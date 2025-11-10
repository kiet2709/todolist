<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;

/**
 * Seeder tạo dữ liệu mẫu (>= 50 bản ghi cho mỗi bảng) dựa trên các migration:
 * - users: uuid, username, email, created_date, updated_date, deleted_date, created_by, updated_by, deleted_by
 *   Tham chiếu: 2025_11_08_091255_create_users_table.php :contentReference[oaicite:0]{index=0}
 *
 * - space_types: uuid, name, created_date, updated_date, deleted_date, created_by, updated_by, deleted_by
 *   Tham chiếu: 2025_11_08_091713_create_space_types_table.php :contentReference[oaicite:1]{index=1}
 *
 * - spaces: uuid, name, url, type_id, lead_id, status, key, created_date, updated_date, deleted_date, created_by, updated_by, deleted_by
 *   Tham chiếu: 2025_11_08_091958_create_spaces_table.php :contentReference[oaicite:2]{index=2}
 *
 * - task_types: uuid, name, created_date, updated_date, deleted_date, created_by, updated_by, deleted_by
 *   Tham chiếu: 2025_11_08_092358_create_task_types_table.php :contentReference[oaicite:3]{index=3}
 *
 * - tasks: uuid, title, description, key, status, assignee, owner, reporter, due_date, priority, parent_id,
 *          task_type_id, space_id, created_date, updated_date, deleted_date, created_by, updated_by, deleted_by
 *   Tham chiếu: 2025_11_08_092501_create_tasks_table.php :contentReference[oaicite:4]{index=4}
 *
 * - comments: uuid, content, user_id, parent_id, created_date, updated_date, deleted_date, created_by, updated_by, deleted_by
 *   Tham chiếu: 2025_11_08_092646_create_comments_table.php :contentReference[oaicite:5]{index=5}
 *
 * - comment_user_tags: comment_id, tagged_user_id
 *   Tham chiếu: 2025_11_08_092801_create_comment_user_tags.php :contentReference[oaicite:6]{index=6}
 *
 * - logs: uuid, content, created_date, task_id
 *   Tham chiếu: 2025_11_08_093011_create_logs_table.php :contentReference[oaicite:7]{index=7}
 *
 * - space_users: space_id, user_id
 *   Tham chiếu: 2025_11_08_093132_create_space_users_table.php :contentReference[oaicite:8]{index=8}
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Bạn có thể bật lên nếu muốn dọn bảng trước khi seed lại (không có ràng buộc FK trong migration nên an toàn).
        DB::table('comment_user_tags')->delete();
        DB::table('logs')->delete();
        DB::table('space_users')->delete();
        DB::table('comments')->delete();
        DB::table('tasks')->delete();
        DB::table('task_types')->delete();
        DB::table('spaces')->delete();
        DB::table('space_types')->delete();
        DB::table('users')->delete();

        DB::transaction(function () {
            $now = Carbon::now();

            // Helper nhỏ gọn, KHÔNG dùng thư viện ngoài
            $pick = fn(array $arr) => $arr[array_rand($arr)];
            $randomPast = function (int $maxDaysAgo = 365): Carbon {
                return Carbon::now()->subDays(random_int(0, $maxDaysAgo))->subMinutes(random_int(0, 1440));
            };
            $randomFuture = function (int $maxDays = 120): Carbon {
                return Carbon::now()->addDays(random_int(0, $maxDays))->addMinutes(random_int(0, 1440));
            };
            $slugify = function (string $text): string {
                $text = strtolower(preg_replace('/[^A-Za-z0-9-]+/', '-', $text));
                return trim(preg_replace('/-+/', '-', $text), '-');
            };
            $uniqueSamples = function (array $pool, int $count) {
                $count = max(0, min($count, count($pool)));
                $keys = array_rand($pool, $count);
                if (!is_array($keys)) $keys = [$keys];
                return array_values(array_intersect_key($pool, array_flip($keys)));
            };

            // 1) USERS (>=50)
            $users = [];
            $userIds = [];
            for ($i = 1; $i <= 50; $i++) {
                $uuid = (string) Str::uuid();
                $userIds[] = $uuid;

                $username = 'user' . str_pad((string)$i, 3, '0', STR_PAD_LEFT);
                $created = $randomPast(400);
                $updated = (clone $created)->addDays(random_int(0, 60));

                $users[] = [
                    'uuid'         => $uuid,
                    'username'     => $username,
                    'email'        => $username . '.' . strtolower(Str::random(6)) . '@example.com',
                    'created_date' => $created,
                    'updated_date' => $updated,
                    'deleted_date' => null,
                    'created_by'   => null,
                    'updated_by'   => null,
                    'deleted_by'   => null,
                ];
            }
            DB::table('users')->insert($users);

            // 2) SPACE TYPES (>=50)
            $spaceTypes = [];
            $spaceTypeIds = [];
            for ($i = 1; $i <= 50; $i++) {
                $uuid = (string) Str::uuid();
                $spaceTypeIds[] = $uuid;

                $name = 'Space Type ' . str_pad((string)$i, 2, '0', STR_PAD_LEFT);
                $created = $randomPast(400);
                $updated = (clone $created)->addDays(random_int(0, 60));

                $spaceTypes[] = [
                    'uuid'         => $uuid,
                    'name'         => $name,
                    'created_date' => $created,
                    'updated_date' => $updated,
                    'deleted_date' => null,
                    'created_by'   => null,
                    'updated_by'   => null,
                    'deleted_by'   => null,
                ];
            }
            DB::table('space_types')->insert($spaceTypes);

            // 3) SPACES (>=50)
            $spaceStatuses = ['active', 'archived', 'pending', 'on_hold'];
            $spaces = [];
            $spaceIds = [];
            for ($i = 1; $i <= 50; $i++) {
                $uuid = (string) Str::uuid();
                $spaceIds[] = $uuid;

                $name = 'Space ' . str_pad((string)$i, 3, '0', STR_PAD_LEFT);
                $key  = 'SPC-' . str_pad((string)$i, 4, '0', STR_PAD_LEFT);
                $url  = 'https://example.com/spaces/' . strtolower($key);
                $type = $pick($spaceTypeIds);
                $lead = $pick($userIds);
                $status = $pick($spaceStatuses);
                $created = $randomPast(300);
                $updated = (clone $created)->addDays(random_int(0, 100));

                $spaces[] = [
                    'uuid'         => $uuid,
                    'name'         => $name,
                    'url'          => $url,
                    'type_id'      => $type,   // string theo migration
                    'lead_id'      => $lead,   // string theo migration
                    'status'       => $status,
                    'key'          => $key,
                    'created_date' => $created,
                    'updated_date' => $updated,
                    'deleted_date' => null,
                    'created_by'   => $lead,
                    'updated_by'   => $lead,
                    'deleted_by'   => null,
                ];
            }
            DB::table('spaces')->insert($spaces);

            // 4) TASK TYPES (>=50)
            $taskTypes = [];
            $taskTypeIds = [];
            $taskTypeBase = [
                'Bug', 'Feature', 'Task', 'Improvement', 'Spike',
                'Epic', 'Story', 'Research', 'Refactor', 'Chore'
            ];
            for ($i = 1; $i <= 50; $i++) {
                $uuid = (string) Str::uuid();
                $taskTypeIds[] = $uuid;

                $name = $taskTypeBase[($i - 1) % count($taskTypeBase)] . ' ' . str_pad((string)$i, 2, '0', STR_PAD_LEFT);
                $created = $randomPast(350);
                $updated = (clone $created)->addDays(random_int(0, 80));

                $taskTypes[] = [
                    'uuid'         => $uuid,
                    'name'         => $name,
                    'created_date' => $created,
                    'updated_date' => $updated,
                    'deleted_date' => null,
                    'created_by'   => null,
                    'updated_by'   => null,
                    'deleted_by'   => null,
                ];
            }
            DB::table('task_types')->insert($taskTypes);

            // 5) TASKS (>=50)
            $taskStatuses = ['todo', 'in_progress', 'review', 'done', 'blocked'];
            $priorities   = ['low', 'medium', 'high', 'urgent', 'critical'];
            $tasks = [];
            $taskIds = [];
            for ($i = 1; $i <= 50; $i++) {
                $uuid = (string) Str::uuid();
                $taskIds[] = $uuid;

                $title = 'Task ' . str_pad((string)$i, 3, '0', STR_PAD_LEFT);
                $desc  = 'Auto-generated description for ' . $title;
                $key   = 'TSK-' . str_pad((string)$i, 4, '0', STR_PAD_LEFT);

                $assignee = $pick($userIds);
                $owner    = $pick($userIds);
                $reporter = $pick($userIds);

                $due      = $randomFuture(180);
                $priority = $pick($priorities);
                $status   = $pick($taskStatuses);
                $taskType = $pick($taskTypeIds);
                $spaceId  = $pick($spaceIds);

                // 25% task con tham chiếu parent_id một task đã tạo trước đó
                $parentId = null;
                if ($i > 5 && random_int(1, 100) <= 25) {
                    $parentId = $taskIds[array_rand($taskIds, 1)];
                }

                $created = $randomPast(250);
                $updated = (clone $created)->addDays(random_int(0, 120));

                $tasks[] = [
                    'uuid'         => $uuid,
                    'title'        => $title,
                    'description'  => $desc,
                    'key'          => $key,
                    'status'       => $status,
                    'assignee'     => $assignee,
                    'owner'        => $owner,
                    'reporter'     => $reporter,
                    'due_date'     => $due,
                    'priority'     => $priority,
                    'parent_id'    => $parentId,
                    'task_type_id' => $taskType,
                    'space_id'     => $spaceId,
                    'created_date' => $created,
                    'updated_date' => $updated,
                    'deleted_date' => null,
                    'created_by'   => $owner,
                    'updated_by'   => $owner,
                    'deleted_by'   => null,
                ];
            }
            DB::table('tasks')->insert($tasks);

            // 6) COMMENTS (>=50)
            $comments = [];
            $commentIds = [];
            for ($i = 1; $i <= 50; $i++) {
                $uuid = (string) Str::uuid();
                $commentIds[] = $uuid;

                $author  = $pick($userIds);
                $content = 'Comment #' . $i . ' by user ' . substr($author, 0, 8);

                // 20% là reply tới comment trước đó
                $parentId = null;
                if ($i > 5 && random_int(1, 100) <= 20) {
                    $parentId = $commentIds[array_rand($commentIds, 1)];
                }

                $created = $randomPast(200);
                $updated = (clone $created)->addDays(random_int(0, 30));

                $comments[] = [
                    'uuid'         => $uuid,
                    'content'      => $content,
                    'user_id'      => $author,
                    'parent_id'    => $parentId,
                    'created_date' => $created,
                    'updated_date' => $updated,
                    'deleted_date' => null,
                    'created_by'   => $author,
                    'updated_by'   => $author,
                    'deleted_by'   => null,
                ];
            }
            DB::table('comments')->insert($comments);

            // 7) COMMENT USER TAGS (>=50) — gắn tag người dùng vào comment
            $commentUserTags = [];
            $pairs = [];
            $targetCount = 100; // nhiều hơn 50 để đa dạng
            for ($i = 0; $i < $targetCount; $i++) {
                $cId = $pick($commentIds);
                $uId = $pick($userIds);
                $pairKey = $cId . '::' . $uId;
                if (isset($pairs[$pairKey])) {
                    $i--;
                    continue;
                }
                $pairs[$pairKey] = true;

                $commentUserTags[] = [
                    'comment_id'     => $cId,
                    'tagged_user_id' => $uId,
                ];
            }
            DB::table('comment_user_tags')->insert($commentUserTags);

            // 8) LOGS (>=50)
            $logs = [];
            for ($i = 1; $i <= 50; $i++) {
                $uuid = (string) Str::uuid();
                $task = $pick($taskIds);
                $created = $randomPast(120);

                $logs[] = [
                    'uuid'         => $uuid,
                    'content'      => 'Log #' . $i . ' for task ' . substr($task, 0, 8),
                    'created_date' => $created, // cột timestamp theo migration, vẫn nhận Carbon
                    'task_id'      => $task,
                ];
            }
            DB::table('logs')->insert($logs);

            // 9) SPACE USERS (>=50) — gán thành viên vào space
            $spaceUsers = [];
            $seen = [];
            foreach ($spaceIds as $spaceId) {
                $members = $uniqueSamples($userIds, random_int(3, 6));
                foreach ($members as $uid) {
                    $key = $spaceId . '::' . $uid;
                    if (isset($seen[$key])) {
                        continue;
                    }
                    $seen[$key] = true;
                    $spaceUsers[] = [
                        'space_id' => $spaceId,
                        'user_id'  => $uid,
                    ];
                }
            }
            // Đảm bảo tối thiểu 50 bản ghi
            if (count($spaceUsers) < 50) {
                while (count($spaceUsers) < 50) {
                    $spaceUsers[] = [
                        'space_id' => $pick($spaceIds),
                        'user_id'  => $pick($userIds),
                    ];
                }
            }
            DB::table('space_users')->insert($spaceUsers);
        });
    }
}
