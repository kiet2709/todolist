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
    /**
     * Tên bảng — chỉnh nếu bạn dùng tên khác
     */
    protected string $table = 'tasks';

    /**
     * Các cột có thể tìm kiếm/điều kiện — controller sẽ tự kiểm tra cột tồn tại hay không.
     */
    protected array $searchableLike = ['title', 'description', 'key'];
    protected array $filterableEq   = ['status', 'priority', 'space_id', 'task_type_id', 'assignee', 'owner', 'reporter'];
    protected array $sortable       = ['created_date', 'updated_date', 'due_date', 'priority', 'status', 'title', 'key'];

    /**
     * Danh sách + filter + sort + phân trang
     * GET /tasks
     * Query:
     *  - q: tìm kiếm text
     *  - status, priority, space_id, task_type_id, assignee, owner, reporter: filter chính xác
     *  - sort: ví dụ "created_date" hoặc "-created_date" (desc)
     *  - per_page: 1..100 (mặc định 15)
     *  - with_trashed: 1 để hiện cả bản ghi đã xóa mềm (nếu có cột deleted_date)
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = max(1, min((int) $request->query('per_page', 15), 100));
        $sortRaw = (string) $request->query('sort', '-created_date');
        [$sortCol, $sortDir] = $this->parseSort($sortRaw);

        $query = DB::table($this->table);

        // Ẩn bản ghi đã xóa mềm nếu có cột deleted_date
        if (Schema::hasColumn($this->table, 'deleted_date') && !$request->boolean('with_trashed')) {
            $query->whereNull('deleted_date');
        }

        // Tìm kiếm toàn văn đơn giản
        $q = trim((string) $request->query('q', ''));
        if ($q !== '') {
            $query->where(function ($sub) use ($q) {
                foreach ($this->searchableLike as $col) {
                    if (Schema::hasColumn($this->table, $col)) {
                        $sub->orWhere($col, 'like', '%' . $q . '%');
                    }
                }
            });
        }

        // Filter bằng so sánh bằng
        foreach ($this->filterableEq as $col) {
            if (Schema::hasColumn($this->table, $col) && $request->filled($col)) {
                $query->where($col, $request->query($col));
            }
        }

        // Sắp xếp
        if (in_array($sortCol, $this->sortable, true) && Schema::hasColumn($this->table, $sortCol)) {
            $query->orderBy($sortCol, $sortDir);
        }

        $paginator = $query->paginate($perPage)->appends($request->query());

        return response()->json($paginator, 200);
    }

    /**
     * Tạo mới
     * POST /tasks
     * Body JSON ví dụ:
     * {
     *   "title": "Implement API",
     *   "description": "Make it clean",
     *   "status": "in_progress",
     *   "priority": "high",
     *   "space_id": "uuid-space",
     *   "task_type_id": "uuid-type",
     *   "assignee": "uuid-user",
     *   "owner": "uuid-user",
     *   "reporter": "uuid-user",
     *   "due_date": "2025-12-31",
     *   "parent_id": null,
     *   "key": "TSK-1001"
     * }
     */
    public function store(Request $request): JsonResponse
    {
        // Validate nhẹ, không ép enum để phù hợp nhiều schema
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

            // Nếu schema của bạn có các cột này:
            'created_by'    => ['nullable', 'uuid', 'exists:users,uuid'],
            'updated_by'    => ['nullable', 'uuid', 'exists:users,uuid'],
        ]);

        $now = Carbon::now();

        // Tự tạo UUID nếu client không gửi
        $data['uuid'] = $data['uuid'] ?? (string) Str::uuid();

        // Tự phát sinh key nếu cần
        if (!isset($data['key']) && Schema::hasColumn($this->table, 'key')) {
            $data['key'] = 'TSK-' . strtoupper(Str::random(6));
        }

        // Gán timestamp nếu schema có
        if (Schema::hasColumn($this->table, 'created_date')) {
            $data['created_date'] = $now;
        }
        if (Schema::hasColumn($this->table, 'updated_date')) {
            $data['updated_date'] = $now;
        }
        if (Schema::hasColumn($this->table, 'deleted_date')) {
            $data['deleted_date'] = null;
        }

        // Nếu có created_by / updated_by mà client không gửi, set = owner (nếu có)
        if (Schema::hasColumn($this->table, 'created_by') && !isset($data['created_by']) && isset($data['owner'])) {
            $data['created_by'] = $data['owner'];
        }
        if (Schema::hasColumn($this->table, 'updated_by') && !isset($data['updated_by']) && isset($data['owner'])) {
            $data['updated_by'] = $data['owner'];
        }

        // Chỉ giữ lại các cột thực sự tồn tại trong bảng
        $insert = $this->filterExistingColumns($data);

        DB::table($this->table)->insert($insert);

        $task = $this->findByUuid($data['uuid'], withTrashed: true);

        return response()->json($task, 201);
    }

    /**
     * Chi tiết
     * GET /tasks/{uuid}
     */
    public function show(Request $request, string $uuid): JsonResponse
    {
        $withTrashed = $request->boolean('with_trashed');
        $task = $this->findByUuid($uuid, $withTrashed);

        if (!$task) {
            return response()->json(['message' => 'Task not found'], 404);
        }
        return response()->json($task, 200);
    }

    /**
     * Cập nhật
     * PUT/PATCH /tasks/{uuid}
     */
    public function update(Request $request, string $uuid): JsonResponse
    {
        $task = $this->findByUuid($uuid, withTrashed: true);
        if (!$task) {
            return response()->json(['message' => 'Task not found'], 404);
        }

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

        // Không cho tự trỏ về chính nó
        if (isset($data['parent_id']) && $data['parent_id'] === $uuid) {
            return response()->json(['message' => 'parent_id cannot equal current task uuid'], 422);
        }

        if (Schema::hasColumn($this->table, 'updated_date')) {
            $data['updated_date'] = Carbon::now();
        }

        $update = $this->filterExistingColumns($data);

        DB::table($this->table)->where('uuid', $uuid)->update($update);

        $fresh = $this->findByUuid($uuid, withTrashed: true);

        return response()->json($fresh, 200);
    }

    /**
     * Xóa
     * DELETE /tasks/{uuid}?force=1
     * - Mặc định: soft delete (set deleted_date = now) nếu có cột deleted_date
     * - Nếu ?force=1 hoặc không có cột deleted_date: xóa hẳn
     */
    public function destroy(Request $request, string $uuid): JsonResponse
    {
        $task = $this->findByUuid($uuid, withTrashed: true);
        if (!$task) {
            return response()->json(['message' => 'Task not found'], 404);
        }

        $force = $request->boolean('force');

        if (Schema::hasColumn($this->table, 'deleted_date') && !$force) {
            $payload = ['deleted_date' => Carbon::now()];
            if (Schema::hasColumn($this->table, 'deleted_by') && $request->filled('deleted_by')) {
                // Cho phép truyền deleted_by nếu schema có
                $payload['deleted_by'] = $request->input('deleted_by');
            }
            DB::table($this->table)->where('uuid', $uuid)->update($payload);

            $fresh = $this->findByUuid($uuid, withTrashed: true);
            return response()->json($fresh, 200);
        }

        DB::table($this->table)->where('uuid', $uuid)->delete();
        return response()->json(['message' => 'Deleted'], 200);
    }

    /**
     * Khôi phục (soft-deleted)
     * PATCH /tasks/{uuid}/restore
     */
    public function restore(string $uuid): JsonResponse
    {
        if (!Schema::hasColumn($this->table, 'deleted_date')) {
            return response()->json(['message' => 'Soft delete not supported for this table'], 400);
        }

        $task = $this->findByUuid($uuid, withTrashed: true);
        if (!$task) {
            return response()->json(['message' => 'Task not found'], 404);
        }

        DB::table($this->table)->where('uuid', $uuid)->update(['deleted_date' => null]);

        $fresh = $this->findByUuid($uuid, withTrashed: false);
        return response()->json($fresh, 200);
    }

    /* =========================
     * Helpers
     * ========================= */

    /**
     * Tách và chuẩn hóa sort string
     * "-created_date" => ['created_date', 'desc']
     */
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

    /**
     * Chỉ giữ lại các cột thực sự tồn tại trong bảng
     */
    protected function filterExistingColumns(array $data): array
    {
        $out = [];
        foreach ($data as $col => $val) {
            if (Schema::hasColumn($this->table, $col)) {
                $out[$col] = $val;
            }
        }
        // Luôn giữ uuid nếu bảng có
        if (!isset($out['uuid']) && isset($data['uuid']) && Schema::hasColumn($this->table, 'uuid')) {
            $out['uuid'] = $data['uuid'];
        }
        return $out;
    }

    /**
     * Tìm theo UUID (mặc định không trả bản ghi đã xóa mềm)
     */
    protected function findByUuid(string $uuid, bool $withTrashed = false): ?array
    {
        $query = DB::table($this->table)->where('uuid', $uuid);

        if (Schema::hasColumn($this->table, 'deleted_date') && !$withTrashed) {
            $query->whereNull('deleted_date');
        }

        $row = (array) $query->first();
        return $row ?: null;
    }

    /* =========================
     * Tùy chọn cho web forms (giữ cho đủ RESTful 7 actions)
     * ========================= */

    public function create(): JsonResponse
    {
        return response()->json(['message' => 'Use POST /tasks to create a task (API controller sample).'], 200);
    }

    public function edit(string $uuid): JsonResponse
    {
        return response()->json(['message' => 'Use PUT/PATCH /tasks/{uuid} to update a task (API controller sample).'], 200);
    }
}
