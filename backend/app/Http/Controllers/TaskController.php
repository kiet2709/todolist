<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Carbon\Carbon;

class TaskController extends Controller
{
    protected string $table = 'tasks';

    protected array $searchableLike = ['title', 'description', 'key'];
    protected array $filterableEq   = ['status', 'priority', 'space_id', 'task_type_id', 'assignee', 'owner', 'reporter'];
    protected array $sortable       = ['created_date', 'updated_date', 'due_date', 'priority', 'status', 'title', 'key'];

    /**
     * Danh sách + filter + sort + phân trang
     * GỌI THEO DẠNG: /?c=Task&m=index&sort=-created_date&page=1&per_page=10
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = max(1, min((int) $request->query('per_page', 15), 100));
        $sortRaw = (string) $request->query('sort', '-created_date');
        [$sortCol, $sortDir] = $this->parseSort($sortRaw);

        // Base
        $query = DB::table($this->table . ' as t');

        // Soft delete
        if (Schema::hasColumn($this->table, 'deleted_date') && !$request->boolean('with_trashed')) {
            $query->whereNull('t.deleted_date');
        }

        // Search
        $q = trim((string) $request->query('q', ''));
        if ($q !== '') {
            $query->where(function ($sub) use ($q) {
                foreach ($this->searchableLike as $col) {
                    if (Schema::hasColumn($this->table, $col)) {
                        $sub->orWhere('t.' . $col, 'like', '%' . $q . '%');
                    }
                }
            });
        }

        // Filters
        foreach ($this->filterableEq as $col) {
            if (Schema::hasColumn($this->table, $col) && $request->filled($col)) {
                $query->where('t.' . $col, $request->query($col));
            }
        }

        // ====== JOIN users & spaces để trả về tên ======
        // users: assignee/owner/reporter
        $query
            ->leftJoin('users as ua', 'ua.uuid', '=', 't.assignee')
            ->leftJoin('users as uo', 'uo.uuid', '=', 't.owner')
            ->leftJoin('users as ur', 'ur.uuid', '=', 't.reporter')
            ->leftJoin('spaces as sp', 'sp.uuid', '=', 't.space_id');

        // Select
        $select = ['t.*'];
        // usernames + emails
        $select[] = DB::raw('ua.username as assignee_username');
        $select[] = DB::raw('ua.email as assignee_email');
        $select[] = DB::raw('uo.username as owner_username');
        $select[] = DB::raw('uo.email as owner_email');
        $select[] = DB::raw('ur.username as reporter_username');
        $select[] = DB::raw('ur.email as reporter_email');
        // space
        $select[] = DB::raw('sp.name as space_name');
        $select[] = DB::raw('sp.key as space_key');

        $query->select($select);

        // Sort
        if (in_array($sortCol, $this->sortable, true) && Schema::hasColumn($this->table, $sortCol)) {
            $query->orderBy('t.' . $sortCol, $sortDir);
        }

        $paginator = $query->paginate($perPage)->appends($request->query());

        return response()->json($paginator, 200);
    }

    /**
     * Tạo mới
     * POST /?c=Task&m=store
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title'         => ['required', 'string', 'max:255'],
            'description'   => ['nullable', 'string'],
            'key'           => ['nullable', 'string', 'max:100'],
            'status'        => ['nullable', 'string', 'max:50'],
            'priority'      => ['nullable', 'string', 'max:50'],
            'assignee'      => ['nullable', 'uuid', 'exists:users,uuid'],
            'owner'         => ['nullable', 'uuid', 'exists:users,uuid'],
            'reporter'      => ['nullable', 'uuid', 'exists:users,uuid'],
            'due_date'      => ['nullable', 'date'],
            'parent_id'     => ['nullable', 'uuid', 'exists:'.$this->table.',uuid'],
            'task_type_id'  => ['nullable', 'uuid', 'exists:task_types,uuid'],
            'space_id'      => ['nullable', 'uuid', 'exists:spaces,uuid'],
            'created_by'    => ['nullable', 'uuid', 'exists:users,uuid'],
            'updated_by'    => ['nullable', 'uuid', 'exists:users,uuid'],
        ]);

        $now = Carbon::now();

        $data['uuid'] = $data['uuid'] ?? (string) Str::uuid();

        if (!isset($data['key']) && Schema::hasColumn($this->table, 'key')) {
            $data['key'] = 'TSK-' . strtoupper(Str::random(6));
        }

        if (Schema::hasColumn($this->table, 'created_date')) $data['created_date'] = $now;
        if (Schema::hasColumn($this->table, 'updated_date')) $data['updated_date'] = $now;
        if (Schema::hasColumn($this->table, 'deleted_date')) $data['deleted_date'] = null;

        if (Schema::hasColumn($this->table, 'created_by') && !isset($data['created_by']) && isset($data['owner'])) {
            $data['created_by'] = $data['owner'];
        }
        if (Schema::hasColumn($this->table, 'updated_by') && !isset($data['updated_by']) && isset($data['owner'])) {
            $data['updated_by'] = $data['owner'];
        }

        $insert = $this->filterExistingColumns($data);

        DB::table($this->table)->insert($insert);

        // Trả về kèm tên như index()
        return $this->showWithJoin($request, $data['uuid']);
    }

    /**
     * Chi tiết
     * GET /?c=Task&m=show&uuid={uuid}
     * (trả về kèm users/spaces join)
     */
    public function show(Request $request): JsonResponse
    {
        $uuid = $request->query('uuid', $request->route('uuid'));
        if (!$uuid) {
            return response()->json(['message' => 'uuid is required'], 422);
        }
        return $this->showWithJoin($request, $uuid);
    }

    /**
     * Cập nhật
     * PUT/PATCH /?c=Task&m=update&uuid={uuid}
     */
    public function update(Request $request): JsonResponse
    {
        $uuid = $request->query('uuid', $request->route('uuid'));
        if (!$uuid) return response()->json(['message' => 'uuid is required'], 422);

        $task = $this->findByUuid($uuid, withTrashed: true);
        if (!$task) return response()->json(['message' => 'Task not found'], 404);

        $data = $request->validate([
            'title'         => ['sometimes', 'string', 'max:255'],
            'description'   => ['sometimes', 'nullable', 'string'],
            'key'           => ['sometimes', 'nullable', 'string', 'max:100'],
            'status'        => ['sometimes', 'nullable', 'string', 'max:50'],
            'priority'      => ['sometimes', 'nullable', 'string', 'max:50'],
            'assignee'      => ['sometimes', 'nullable', 'uuid', 'exists:users,uuid'],
            'owner'         => ['sometimes', 'nullable', 'uuid', 'exists:users,uuid'],
            'reporter'      => ['sometimes', 'nullable', 'uuid', 'exists:users,uuid'],
            'due_date'      => ['sometimes', 'nullable', 'date'],
            'parent_id'     => ['sometimes', 'nullable', 'uuid', 'exists:'.$this->table.',uuid'],
            'task_type_id'  => ['sometimes', 'nullable', 'uuid', 'exists:task_types,uuid'],
            'space_id'      => ['sometimes', 'nullable', 'uuid', 'exists:spaces,uuid'],
            'updated_by'    => ['sometimes', 'nullable', 'uuid', 'exists:users,uuid'],
        ]);

        if (isset($data['parent_id']) && $data['parent_id'] === $uuid) {
            return response()->json(['message' => 'parent_id cannot equal current task uuid'], 422);
        }

        if (Schema::hasColumn($this->table, 'updated_date')) {
            $data['updated_date'] = Carbon::now();
        }

        $update = $this->filterExistingColumns($data);

        DB::table($this->table)->where('uuid', $uuid)->update($update);

        return $this->showWithJoin($request, $uuid);
    }

    /**
     * Xóa
     * DELETE /?c=Task&m=destroy&uuid={uuid}&force=0|1
     */
    public function destroy(Request $request): JsonResponse
    {
        $uuid = $request->query('uuid', $request->route('uuid'));
        if (!$uuid) return response()->json(['message' => 'uuid is required'], 422);

        $task = $this->findByUuid($uuid, withTrashed: true);
        if (!$task) return response()->json(['message' => 'Task not found'], 404);

        $force = $request->boolean('force');

        if (Schema::hasColumn($this->table, 'deleted_date') && !$force) {
            $payload = ['deleted_date' => Carbon::now()];
            if (Schema::hasColumn($this->table, 'deleted_by') && $request->filled('deleted_by')) {
                $payload['deleted_by'] = $request->input('deleted_by');
            }
            DB::table($this->table)->where('uuid', $uuid)->update($payload);
            return $this->showWithJoin($request, $uuid, withTrashed: true);
        }

        DB::table($this->table)->where('uuid', $uuid)->delete();
        return response()->json(['message' => 'Deleted'], 200);
    }

    /**
     * Khôi phục (soft-deleted)
     * PATCH /?c=Task&m=restore&uuid={uuid}
     */
    public function restore(Request $request): JsonResponse
    {
        if (!Schema::hasColumn($this->table, 'deleted_date')) {
            return response()->json(['message' => 'Soft delete not supported for this table'], 400);
        }

        $uuid = $request->query('uuid', $request->route('uuid'));
        if (!$uuid) return response()->json(['message' => 'uuid is required'], 422);

        $task = $this->findByUuid($uuid, withTrashed: true);
        if (!$task) return response()->json(['message' => 'Task not found'], 404);

        DB::table($this->table)->where('uuid', $uuid)->update(['deleted_date' => null]);

        return $this->showWithJoin($request, $uuid, withTrashed: false);
    }

    /* ========================= Helpers ========================= */

    protected function parseSort(string $input): array
    {
        $input = trim($input);
        $dir = 'asc';
        if (str_starts_with($input, '-')) {
            $dir = 'desc';
            $input = substr($input, 1);
        }
        return [$input, $dir];
    }

    protected function filterExistingColumns(array $data): array
    {
        $out = [];
        foreach ($data as $col => $val) {
            if (Schema::hasColumn($this->table, $col)) {
                $out[$col] = $val;
            }
        }
        if (!isset($out['uuid']) && isset($data['uuid']) && Schema::hasColumn($this->table, 'uuid')) {
            $out['uuid'] = $data['uuid'];
        }
        return $out;
    }

    protected function findByUuid(string $uuid, bool $withTrashed = false): ?array
    {
        $query = DB::table($this->table)->where('uuid', $uuid);
        if (Schema::hasColumn($this->table, 'deleted_date') && !$withTrashed) {
            $query->whereNull('deleted_date');
        }
        $row = (array) $query->first();
        return $row ?: null;
    }

    /**
     * Lấy 1 task kèm join users/spaces (dùng cho show/store/update/destroy/restore)
     */
    protected function showWithJoin(Request $request, string $uuid, bool $withTrashed = true): JsonResponse
    {
        $q = DB::table($this->table.' as t')
            ->leftJoin('users as ua', 'ua.uuid', '=', 't.assignee')
            ->leftJoin('users as uo', 'uo.uuid', '=', 't.owner')
            ->leftJoin('users as ur', 'ur.uuid', '=', 't.reporter')
            ->leftJoin('spaces as sp', 'sp.uuid', '=', 't.space_id')
            ->where('t.uuid', $uuid);

        if (Schema::hasColumn($this->table, 'deleted_date') && !$withTrashed) {
            $q->whereNull('t.deleted_date');
        }

        $row = $q->select([
            't.*',
            DB::raw('ua.username as assignee_username'),
            DB::raw('ua.email as assignee_email'),
            DB::raw('uo.username as owner_username'),
            DB::raw('uo.email as owner_email'),
            DB::raw('ur.username as reporter_username'),
            DB::raw('ur.email as reporter_email'),
            DB::raw('sp.name as space_name'),
            DB::raw('sp.key as space_key'),
        ])->first();

        if (!$row) return response()->json(['message'=>'Task not found'], 404);
        return response()->json((array) $row, 200);
    }

    /* ========================= Optional stubs for completeness ========================= */

    public function create(): JsonResponse
    {
        return response()->json(['message' => 'Use POST /?c=Task&m=store to create a task (API controller sample).'], 200);
    }

    public function edit(Request $request): JsonResponse
    {
        $uuid = $request->query('uuid', $request->route('uuid'));
        return response()->json(['message' => 'Use PUT/PATCH /?c=Task&m=update&uuid='.$uuid.' to update a task (API controller sample).'], 200);
    }
}
