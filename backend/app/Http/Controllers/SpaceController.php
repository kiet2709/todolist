<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Support\Str;
use Carbon\Carbon;
use Throwable;

class SpaceController extends Controller
{
    /**
     * GET /?c=Space&m=index
     * - Tìm kiếm q theo name/key/url
     * - Lọc theo type_id, lead_id, status
     * - Sắp xếp sort_by (whitelist) & sort_dir
     * - Phân trang per_page
     */
    public function index(Request $request)
    {
        // Validate query params
        $validated = $request->validate([
            'q'         => ['nullable', 'string', 'max:255'],
            'type_id'   => ['nullable', 'string', 'max:64'],
            'lead_id'   => ['nullable', 'string', 'max:64'],
            'status'    => ['nullable', 'string', 'max:64'],
            'sort_by'   => ['nullable', 'string', 'in:name,key,created_date,updated_date,status'],
            'sort_dir'  => ['nullable', 'string', 'in:asc,desc'],
            'per_page'  => ['nullable', 'integer', 'min:1', 'max:100'],
            // 'page' Laravel tự đọc, không bắt buộc validate
        ]);

        $q        = $validated['q'] ?? null;
        $typeId   = $validated['type_id'] ?? null;
        $leadId   = $validated['lead_id'] ?? null;
        $status   = $validated['status'] ?? null;
        $sortBy   = $validated['sort_by'] ?? 'created_date';
        $sortDir  = $validated['sort_dir'] ?? 'desc';
        $perPage  = $validated['per_page'] ?? 15;

        $query = DB::table('spaces as s')
            ->leftJoin('space_types as st', 'st.uuid', '=', 's.type_id')
            ->leftJoin('users as u', 'u.uuid', '=', 's.lead_id')
            ->whereNull('s.deleted_date')
            ->select(
                's.uuid',
                's.name',
                's.url',
                's.type_id',
                DB::raw('st.name as type_name'),
                's.lead_id',
                DB::raw('u.username as lead_username'),
                DB::raw('u.email as lead_email'),
                's.status',
                's.key',
                's.created_date',
                's.updated_date'
            );

        if ($q) {
            $query->where(function ($sub) use ($q) {
                $like = '%' . str_replace(['%', '_'], ['\\%', '\\_'], $q) . '%';
                $sub->where('s.name', 'like', $like)
                    ->orWhere('s.key', 'like', $like)
                    ->orWhere('s.url', 'like', $like);
            });
        }

        if ($typeId) {
            $query->where('s.type_id', $typeId);
        }

        if ($leadId) {
            $query->where('s.lead_id', $leadId);
        }

        if ($status) {
            $query->where('s.status', $status);
        }

        // Whitelist cột sắp xếp đã validate ở trên
        $query->orderBy("s.$sortBy", $sortDir);

        $result = $query->paginate($perPage);

        return response()->json($result);
    }

    /**
     * GET /?c=Space&m=show&uuid={uuid}
     */
    public function show(Request $request)
    {
        $uuid = $request->query('uuid', $request->input('uuid'));
        if (!$uuid) {
            return response()->json(['message' => 'uuid is required'], 422);
        }

        $space = DB::table('spaces as s')
            ->leftJoin('space_types as st', 'st.uuid', '=', 's.type_id')
            ->leftJoin('users as u', 'u.uuid', '=', 's.lead_id')
            ->where('s.uuid', $uuid)
            ->whereNull('s.deleted_date')
            ->select(
                's.uuid',
                's.name',
                's.url',
                's.type_id',
                DB::raw('st.name as type_name'),
                's.lead_id',
                DB::raw('u.username as lead_username'),
                DB::raw('u.email as lead_email'),
                's.status',
                's.key',
                's.created_date',
                's.updated_date',
                's.created_by',
                's.updated_by'
            )
            ->first();

        if (!$space) {
            return response()->json(['message' => 'Space not found'], 404);
        }

        return response()->json(['data' => $space]);
    }

    /**
     * POST /?c=Space&m=store
     */
    public function store(Request $request)
    {
        // Lưu ý: dùng exists tới bảng space_types/users để đảm bảo FK hợp lệ (nếu dùng)
        $validated = $request->validate([
            'name'     => ['required', 'string', 'max:255'],
            'url'      => ['nullable', 'string', 'max:255'],
            'type_id'  => [
                'nullable', 'string', 'max:64',
                Rule::exists('space_types', 'uuid')->where(function ($q) {
                    $q->whereNull('deleted_date');
                }),
            ],
            'lead_id'  => [
                'nullable', 'string', 'max:64',
                // không ràng deleted_date vì nhiều bảng users không có cột này
                Rule::exists('users', 'uuid'),
            ],
            'status'   => ['nullable', 'string', 'max:64'],
            'key'      => [
                'nullable', 'string', 'max:64',
                Rule::unique('spaces', 'key')->where(function ($q) {
                    $q->whereNull('deleted_date');
                }),
            ],
        ]);

        $now   = Carbon::now();
        $uuid  = (string) Str::uuid();
        $actor = $request->user()->uuid ?? $request->user()->id ?? null;

        $payload = [
            'uuid'         => $uuid,
            'name'         => $validated['name'],
            'url'          => $validated['url'] ?? null,
            'type_id'      => $validated['type_id'] ?? null,
            'lead_id'      => $validated['lead_id'] ?? null,
            'status'       => $validated['status'] ?? null,
            'key'          => $validated['key'] ?? null,
            'created_date' => $now,
            'updated_date' => $now,
            'created_by'   => $actor,
            'updated_by'   => $actor,
            'deleted_date' => null,
            'deleted_by'   => null,
        ];

        try {
            DB::transaction(function () use ($payload) {
                DB::table('spaces')->insert($payload);
            });

            $created = DB::table('spaces')->where('uuid', $uuid)->first();

            return response()->json([
                'message' => 'Created',
                'data'    => $created,
            ], 201);
        } catch (Throwable $e) {
            return response()->json([
                'message' => 'Create failed',
                'error'   => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    /**
     * PUT/PATCH /?c=Space&m=update&uuid={uuid}
     */
    public function update(Request $request)
    {
        $uuid = $request->query('uuid', $request->input('uuid'));
        if (!$uuid) {
            return response()->json(['message' => 'uuid is required'], 422);
        }

        // Kiểm tra tồn tại + chưa bị xóa mềm
        $exists = DB::table('spaces')->where('uuid', $uuid)->whereNull('deleted_date')->exists();
        if (!$exists) {
            return response()->json(['message' => 'Space not found'], 404);
        }

        $validated = $request->validate([
            'name'     => ['sometimes', 'required', 'string', 'max:255'],
            'url'      => ['sometimes', 'nullable', 'string', 'max:255'],
            'type_id'  => [
                'sometimes', 'nullable', 'string', 'max:64',
                Rule::exists('space_types', 'uuid')->where(function ($q) {
                    $q->whereNull('deleted_date');
                }),
            ],
            'lead_id'  => [
                'sometimes', 'nullable', 'string', 'max:64',
                Rule::exists('users', 'uuid'),
            ],
            'status'   => ['sometimes', 'nullable', 'string', 'max:64'],
            'key'      => [
                'sometimes', 'nullable', 'string', 'max:64',
                Rule::unique('spaces', 'key')
                    ->where(function ($q) {
                        $q->whereNull('deleted_date');
                    })
                    ->ignore($uuid, 'uuid'),
            ],
        ]);

        $now   = Carbon::now();
        $actor = $request->user()->uuid ?? $request->user()->id ?? null;

        // Chỉ cập nhật những field gửi lên
        $updatable = ['name', 'url', 'type_id', 'lead_id', 'status', 'key'];
        $data = array_intersect_key($validated, array_flip($updatable));
        $data['updated_date'] = $now;
        $data['updated_by']   = $actor;

        try {
            DB::transaction(function () use ($uuid, $data) {
                DB::table('spaces')
                    ->where('uuid', $uuid)
                    ->whereNull('deleted_date')
                    ->update($data);
            });

            $updated = DB::table('spaces')->where('uuid', $uuid)->first();

            return response()->json([
                'message' => 'Updated',
                'data'    => $updated,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'message' => 'Update failed',
                'error'   => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    /**
     * DELETE /?c=Space&m=destroy&uuid={uuid}
     * - Soft delete bằng cách set deleted_date & deleted_by
     */
    public function destroy(Request $request)
    {
        $uuid = $request->query('uuid', $request->input('uuid'));
        if (!$uuid) {
            return response()->json(['message' => 'uuid is required'], 422);
        }

        $exists = DB::table('spaces')->where('uuid', $uuid)->whereNull('deleted_date')->exists();
        if (!$exists) {
            return response()->json(['message' => 'Space not found'], 404);
        }

        $now   = Carbon::now();
        $actor = $request->user()->uuid ?? $request->user()->id ?? null;

        try {
            DB::transaction(function () use ($uuid, $now, $actor) {
                DB::table('spaces')
                    ->where('uuid', $uuid)
                    ->whereNull('deleted_date')
                    ->update([
                        'deleted_date' => $now,
                        'deleted_by'   => $actor,
                    ]);
            });

            return response()->json(null, 204);
        } catch (Throwable $e) {
            return response()->json([
                'message' => 'Delete failed',
                'error'   => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    /**
     * POST /?c=Space&m=restore&uuid={uuid}
     * - Phục hồi soft delete (nếu cần)
     */
    public function restore(Request $request)
    {
        $uuid = $request->query('uuid', $request->input('uuid'));
        if (!$uuid) {
            return response()->json(['message' => 'uuid is required'], 422);
        }

        $exists = DB::table('spaces')->where('uuid', $uuid)->whereNotNull('deleted_date')->exists();
        if (!$exists) {
            return response()->json(['message' => 'Space not found or not deleted'], 404);
        }

        try {
            DB::transaction(function () use ($uuid) {
                DB::table('spaces')
                    ->where('uuid', $uuid)
                    ->update([
                        'deleted_date' => null,
                        'deleted_by'   => null,
                    ]);
            });

            $restored = DB::table('spaces')->where('uuid', $uuid)->first();

            return response()->json([
                'message' => 'Restored',
                'data'    => $restored,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'message' => 'Restore failed',
                'error'   => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    /**
     * GET /?c=Space&m=types
     * Trả về options cho select type_id
     */
    public function types(Request $request)
    {
        $rows = DB::table('space_types')
            ->whereNull('deleted_date')
            ->orderBy('name')
            ->select('uuid', 'name')
            ->get();

        $options = $rows->map(fn($r) => [
            'value' => $r->uuid,
            'label' => $r->name,
        ])->values();

        return response()->json(['data' => $options]);
    }

    /**
     * GET /?c=Space&m=leads
     * Trả về options cho select lead_id
     */
    public function leads(Request $request)
    {
        // Chọn username/name + email (COALESCE phòng khi 1 trong 2 cột không có)
        $rows = DB::table('users')
            ->orderBy('username')
            ->select(
                'uuid',
                DB::raw('COALESCE(username) as label_name'),
                'email'
            )
            ->get();

        $options = $rows->map(function ($r) {
            $label = trim(($r->label_name ?? '') . ($r->email ? " ({$r->email})" : ''));
            return [
                'value' => $r->uuid,
                'label' => $label ?: $r->uuid,
            ];
        })->values();

        return response()->json(['data' => $options]);
    }

    /**
     * GET /?c=Space&m=statuses
     * Trả về danh sách status distinct để populate filter
     */
    public function statuses(Request $request)
    {
        $rows = DB::table('spaces')
            ->whereNull('deleted_date')
            ->whereNotNull('status')
            ->distinct()
            ->orderBy('status')
            ->pluck('status');

        $options = $rows->map(fn($s) => ['value' => $s, 'label' => $s])->values();

        return response()->json(['data' => $options]);
    }
}
