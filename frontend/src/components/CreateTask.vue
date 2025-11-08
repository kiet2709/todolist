<template>
  <!-- Modal tạo task -->
  <div>
    <!-- v-model:open="open"
    title="Create Task"
    width="760px"
    :footer="null"
    :body-style="{ padding: 0 }"
    class="create-task-modal"
  > -->
    <!-- đầu modal -->
    <div class="header-bar">
      <div class="title">Create Task</div>
      <div class="subtitle">Required fields are marked with an asterisk *</div>
    </div>

    <!-- phần nội dung cuộn được -->
    <div class="body-scroll">
      <a-form
        layout="vertical"
        :model="formState"
        ref="formRef"
        @finish="onFinish"
      >
        <!-- 1. Space + Work type -->
        <div class="grid-2">
          <a-form-item label="Space *" name="space" :rules="[{ required: true, message: 'Please select space' }]">
            <a-select v-model:value="formState.space" placeholder="Select space">
              <a-select-option value="todo">🗂 To Do List System (KAN)</a-select-option>
              <a-select-option value="marketing">Marketing</a-select-option>
              <a-select-option value="dev">Development</a-select-option>
            </a-select>
          </a-form-item>

          <a-form-item label="Work type *" name="workType" :rules="[{ required: true, message: 'Please select work type' }]">
            <a-select v-model:value="formState.workType">
              <a-select-option value="task">Task</a-select-option>
              <a-select-option value="bug">Bug</a-select-option>
              <a-select-option value="story">Story</a-select-option>
            </a-select>
          </a-form-item>
        </div>

        <a-divider />

        <!-- 2. Status -->
        <a-form-item label="Status" name="status">
          <a-select v-model:value="formState.status">
            <a-select-option value="todo">To Do</a-select-option>
            <a-select-option value="inprogress">In progress</a-select-option>
            <a-select-option value="done">Done</a-select-option>
          </a-select>
          <div class="small-hint">This is the initial status upon creation</div>
        </a-form-item>

        <!-- 3. Summary (required) -->
        <a-form-item
          label="Summary *"
          name="summary"
          :rules="[{ required: true, message: 'Summary is required' }]"
        >
          <a-input v-model:value="formState.summary" placeholder="Enter summary" />
        </a-form-item>

        <!-- 4. Description -->
        <a-form-item label="Description" name="description">
          <!-- thực tế bạn có thể thay bằng editor khác, ở đây xài textarea -->
          <a-textarea
            v-model:value="formState.description"
            :rows="5"
            placeholder="Paste a Confluence or Loom link here, and we’ll generate a description automatically from the contents."
          />
        </a-form-item>

        <!-- 5. Assignee + Priority -->
        <div class="grid-2">
          <a-form-item label="Assignee" name="assignee">
            <a-select
              v-model:value="formState.assignee"
              placeholder="Select assignee"
              allow-clear
            >
              <a-select-option value="auto">Automatic</a-select-option>
              <a-select-option value="me">Assign to me</a-select-option>
              <a-select-option value="arjun">Arjun</a-select-option>
              <a-select-option value="pg">PG</a-select-option>
            </a-select>
          </a-form-item>

          <a-form-item label="Priority" name="priority">
            <a-select v-model:value="formState.priority">
              <a-select-option value="low">Low</a-select-option>
              <a-select-option value="medium">Medium</a-select-option>
              <a-select-option value="high">High</a-select-option>
              <a-select-option value="critical">Critical</a-select-option>
            </a-select>
          </a-form-item>
        </div>

        <!-- 6. Parent + Due date -->
        <div class="grid-2">
          <a-form-item label="Parent" name="parent">
            <a-select v-model:value="formState.parent" allow-clear placeholder="Select parent">
              <a-select-option value="KAN-1">KAN-1</a-select-option>
              <a-select-option value="KAN-2">KAN-2</a-select-option>
              <a-select-option value="KAN-3">KAN-3</a-select-option>
            </a-select>
            <div class="small-hint">
              Your work type hierarchy determines the work items you can select here.
            </div>
          </a-form-item>

          <a-form-item label="Due date" name="dueDate">
            <a-date-picker v-model:value="formState.dueDate" style="width: 100%;" />
          </a-form-item>
        </div>

        <!-- 7. Labels + Team -->
        <div class="grid-2">
          <a-form-item label="Labels" name="labels">
            <a-select
              v-model:value="formState.labels"
              mode="tags"
              placeholder="Select label"
              allow-clear
            >
              <a-select-option value="frontend">frontend</a-select-option>
              <a-select-option value="backend">backend</a-select-option>
              <a-select-option value="urgent">urgent</a-select-option>
            </a-select>
          </a-form-item>

          <a-form-item label="Team" name="team">
            <a-select v-model:value="formState.team" placeholder="Choose a team" allow-clear>
              <a-select-option value="ems">EMS Team</a-select-option>
              <a-select-option value="fmcs">FMCS Team</a-select-option>
              <a-select-option value="iot">IoT Team</a-select-option>
            </a-select>
            <div class="small-hint">
              Associates a team to an issue. You can use this field to search and filter issues by team.
            </div>
          </a-form-item>
        </div>

        <!-- 8. Start date -->
        <a-form-item label="Start date" name="startDate">
          <a-date-picker v-model:value="formState.startDate" style="width: 100%;" />
          <div class="small-hint">
            Allows the planned start date for a piece of work to be set.
          </div>
        </a-form-item>

        <!-- 9. Attachment -->
        <a-form-item label="Attachment" name="attachment">
          <a-upload-dragger
            name="file"
            :multiple="true"
            :before-upload="() => false"
          >
            <p class="ant-upload-drag-icon">
              <upload-outlined />
            </p>
            <p class="ant-upload-text">Drop files to attach or <a>Browse</a></p>
          </a-upload-dragger>
        </a-form-item>

        <!-- 10. Linked work items + Restrict to -->
        <div class="grid-2">
          <a-form-item label="Linked Work items" name="linked">
            <a-select v-model:value="formState.linked" placeholder="blocks">
              <a-select-option value="blocks">blocks</a-select-option>
              <a-select-option value="relates">relates to</a-select-option>
              <a-select-option value="duplicates">duplicates</a-select-option>
            </a-select>
          </a-form-item>

          <a-form-item label="Restrict to" name="restrict">
            <a-select v-model:value="formState.restrict" placeholder="Select Roles" allow-clear>
              <a-select-option value="admin">Admin</a-select-option>
              <a-select-option value="manager">Manager</a-select-option>
              <a-select-option value="viewer">Viewer</a-select-option>
            </a-select>
          </a-form-item>
        </div>

        <!-- 11. Flagged -->
        <a-form-item name="flagged" class="flag-box">
          <a-checkbox v-model:checked="formState.flagged">
            Impediment
          </a-checkbox>
          <div class="small-hint">
            Allows to flag issues with impediments.
          </div>
        </a-form-item>

        <!-- 12. Create another -->
        <a-form-item name="createAnother">
          <a-checkbox v-model:checked="formState.createAnother">
            Create another
          </a-checkbox>
        </a-form-item>

        <!-- footer -->
        <div class="footer-actions">
          <a-button @click="onCancel">Cancel</a-button>
          <a-button type="primary" html-type="submit">Create</a-button>
        </div>
      </a-form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { UploadOutlined } from '@ant-design/icons-vue'

const open = ref(true) // mở sẵn để bạn nhìn demo
const formRef = ref()

const formState = reactive({
  space: 'todo',
  workType: 'task',
  status: 'todo',
  summary: '',
  description: '',
  assignee: 'auto',
  priority: 'medium',
  parent: undefined,
  dueDate: null,
  labels: [],
  team: undefined,
  startDate: null,
  attachment: [],
  linked: 'blocks',
  restrict: undefined,
  flagged: false,
  createAnother: false
})

const onFinish = () => {
  console.log('form data:', { ...formState })
  if (!formState.createAnother) {
    open.value = false
  }
}

const onCancel = () => {
  open.value = false
}
</script>

<style scoped>
.create-task-modal :deep(.ant-modal-content) {
  padding: 0;
}
.header-bar {
  padding: 16px 24px 8px;
}
.title {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 4px;
}
.subtitle {
  font-size: 12px;
  color: #9ca3af;
}
.body-scroll {
  max-height: 68vh; /* để cuộn giống hình bạn */
  overflow-y: auto;
  padding: 0 24px 16px;
}
.grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}
.small-hint {
  font-size: 12px;
  color: #6b7280;
  margin-top: 4px;
}
.footer-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 16px;
  padding-bottom: 8px;
}
.flag-box {
  margin-top: 4px;
}
@media (max-width: 640px) {
  .grid-2 {
    grid-template-columns: 1fr;
  }
  .body-scroll {
    max-height: 75vh;
  }
}
</style>
