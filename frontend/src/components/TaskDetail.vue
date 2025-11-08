<template>
  <div class="issue-page">
    <!-- HEADER -->
    <header class="issue-header">
      <div class="left">
        <a-breadcrumb separator="/">
          <a-breadcrumb-item>Add epic</a-breadcrumb-item>
          <a-breadcrumb-item>KAN-1</a-breadcrumb-item>
        </a-breadcrumb>
        <h1 class="issue-title">Task 1</h1>
      </div>

      <div class="right">
        <!-- STATUS -->
        <a-dropdown trigger="click">
          <a-button class="header-status" :class="headerStatusClass">
            <span class="status-dot" :class="headerDotClass"></span>
            {{ headerStatusLabel }}
            <DownOutlined />
          </a-button>
          <template #overlay>
            <a-menu @click="onHeaderStatusClick">
              <a-menu-item v-for="opt in issueStatusOptions" :key="opt.value">
                {{ opt.label }}
              </a-menu-item>
            </a-menu>
          </template>
        </a-dropdown>

        <!-- ICONS -->
        <div class="icon-buttons">
          <a-badge :count="1" offset="[-6, 3]">
            <a-button shape="circle" size="small">
              <EyeOutlined />
            </a-button>
          </a-badge>

          <a-button shape="circle" size="small">
            <MoreOutlined />
          </a-button>

          <a-button shape="circle" size="small" danger>
            <CloseOutlined />
          </a-button>
        </div>
      </div>
    </header>

    <!-- BODY -->
    <div class="issue-body">
      <!-- LEFT -->
      <div class="main-column">
        <!-- DESCRIPTION -->
        <section class="panel">
          <div class="panel-head">
            <h2 class="panel-title">Description</h2>
            <a-button
              v-if="!isEditingDescription"
              type="link"
              size="small"
              @click="startEditDescription"
            >
              Edit
            </a-button>
          </div>

          <!-- edit -->
          <div v-if="isEditingDescription" class="description-editor">
            <div class="editor-toolbar">
              <button
                @click="editor?.chain().focus().toggleBold().run()"
                :class="{ active: editor?.isActive('bold') }"
              >B</button>
              <button
                @click="editor?.chain().focus().toggleItalic().run()"
                :class="{ active: editor?.isActive('italic') }"
              ><i>I</i></button>
              <button
                @click="editor?.chain().focus().toggleBulletList().run()"
                :class="{ active: editor?.isActive('bulletList') }"
              >•</button>
              <button
                @click="editor?.chain().focus().toggleOrderedList().run()"
                :class="{ active: editor?.isActive('orderedList') }"
              >1.</button>
            </div>
            <EditorContent v-if="editor" :editor="editor" class="editor-body" />
            <div class="editor-actions">
              <a-button type="primary" size="small" @click="saveDescription">Save</a-button>
              <a-button size="small" type="text" @click="cancelDescription">Cancel</a-button>
            </div>
          </div>

          <!-- view -->
          <div v-else>
            <div
              v-if="description"
              class="description-display"
              v-html="description"
              @click="startEditDescription"
            ></div>
            <div
              v-else
              class="description-placeholder"
              @click="startEditDescription"
            >
              Add a description...
            </div>
          </div>
        </section>

        <!-- SUBTASKS -->
        <section class="panel">
          <div class="subtasks-top">
            <h2 class="panel-title">Subtasks</h2>
            <a-space>
              <!-- <a-button type="text" size="small">
                <MoreOutlined />
              </a-button>
              <a-button type="text" size="small">
                <SettingOutlined />
              </a-button> -->
              <a-button type="text" size="small" @click="showCreate = !showCreate">
                <PlusOutlined />
              </a-button>
            </a-space>
          </div>

          <!-- progress -->
          <div class="progress-row">
            <div class="progress-track">
              <div class="progress-seg done" :style="{ width: statusPercents.done + '%' }"></div>
              <div class="progress-seg in-progress" :style="{ width: statusPercents.inProgress + '%' }"></div>
              <div class="progress-seg in-review" :style="{ width: statusPercents.inReview + '%' }"></div>
              <div class="progress-seg todo" :style="{ width: statusPercents.todo + '%' }"></div>
            </div>
            <span class="progress-label">{{ Math.round(statusPercents.done) }}% Done</span>
          </div>

          <!-- create row -->
          <div v-if="showCreate" class="create-row">
            <a-input
              v-model:value="newSubtask.title"
              placeholder="What should I do next?"
              @pressEnter="addSubtask"
            />
            <a-select
              v-model:value="newSubtask.priority"
              style="width:110px"
              :options="priorityOptions.map(p => ({ label: p, value: p }))"
            />
            <a-button type="primary" @click="addSubtask">Create</a-button>
          </div>

          <!-- table -->
          <a-table
            :columns="subtaskColumns"
            :data-source="subtasks"
            :pagination="false"
            :scroll="{ y: 210 }"
            size="small"
            row-key="key"
          >
            <template #bodyCell="{ column, record, index }">
              <!-- Work -->
              <template v-if="column.dataIndex === 'work'">
                <span class="issue-key">{{ record.key }}</span>
                {{ record.title }}
              </template>

              <!-- Priority -->
              <template v-else-if="column.dataIndex === 'priority'">
                <a-dropdown trigger="click">
                  <span class="priority-chip">
                    = {{ record.priority }}
                    <DownOutlined style="font-size: 10px" />
                  </span>
                  <template #overlay>
                    <a-menu @click="({ key }) => setSubtaskPriority(index, key)">
                      <a-menu-item v-for="p in priorityOptions" :key="p">{{ p }}</a-menu-item>
                    </a-menu>
                  </template>
                </a-dropdown>
              </template>

              <!-- Assignee -->
              <template v-else-if="column.dataIndex === 'assignee'">
                <a-space>
                  <a-avatar size="small">{{ record.assignee?.slice(0, 2) || 'Un' }}</a-avatar>
                  <span>{{ record.assignee || 'Unassigned' }}</span>
                </a-space>
              </template>

              <!-- Status -->
              <template v-else-if="column.dataIndex === 'status'">
                <a-dropdown trigger="click">
                  <span class="status-pill" :class="pillClass(record.status)">
                    {{ displayStatus(record.status) }}
                    <DownOutlined style="font-size: 10px" />
                  </span>
                  <template #overlay>
                    <a-menu @click="({ key }) => setTaskStatus(index, key)">
                      <a-menu-item v-for="opt in statusOptions" :key="opt.value">
                        {{ opt.label }}
                      </a-menu-item>
                    </a-menu>
                  </template>
                </a-dropdown>
              </template>
            </template>
          </a-table>
        </section>

        <!-- ACTIVITY -->
        <section class="panel activity-panel">
          <div class="panel-top-row">
            <h2 class="panel-title">Activity</h2>
          </div>

          <a-tabs v-model:activeKey="activeTab" size="small">
            <a-tab-pane key="All" tab="All" />
            <a-tab-pane key="Comments" tab="Comments" />
            <a-tab-pane key="History" tab="History" />
          </a-tabs>

          <!-- COMMENTS -->
          <div v-if="activeTab === 'Comments'">
            <div v-for="c in comments" :key="c.id" class="comment-item">
              <a-avatar size="small" style="background:#e0ecff;color:#000;">{{ c.initials }}</a-avatar>
              <div class="comment-body">
                <div class="comment-header">
                  <span class="comment-name">{{ c.user }}</span>
                  <span class="comment-time">{{ formatTimeAgo(c.createdAt) }}</span>
                </div>
                <div class="comment-content">
                  {{ c.content }}
                </div>
                <div class="comment-actions">
                  <a-button type="link" size="small">Reply</a-button>
                  <a-button type="link" size="small" @click="deleteComment(c.id)">Delete</a-button>
                </div>
              </div>
            </div>

            <!-- add comment -->
            <div class="comment-add">
              <a-avatar size="small" style="background:#e0ecff">HH</a-avatar>
              <div class="comment-editor">
                <a-mentions
                  v-model:value="newComment"
                  :options="mentionOptions"
                  rows="3"
                  placeholder="Write a comment..."
                />
                <div class="comment-editor-actions">
                  <a-button type="primary" size="small" @click="saveComment">Save</a-button>
                  <a-button size="small" type="text" @click="cancelComment">Cancel</a-button>
                </div>
              </div>
            </div>
          </div>

          <!-- HISTORY -->
          <div v-else-if="activeTab === 'History' || activeTab === 'All'">
            <div v-for="item in historyItems" :key="item.id" class="history-item">
              <a-avatar size="small" style="background:#6d28d9">{{ item.initials }}</a-avatar>
              <div class="history-body">
                <div class="history-row">
                  <span class="history-name">{{ item.user }}</span>
                  <span class="history-action">{{ item.action }}</span>
                </div>
                <div class="history-time">{{ item.timeAgo }}</div>
                <div v-if="item.type === 'status'" class="history-change">
                  <span class="status-pill pill-todo">{{ item.from }}</span>
                  <span class="history-arrow">→</span>
                  <span class="status-pill" :class="pillClass(item.to)">{{ item.to }}</span>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>

      <!-- RIGHT -->
      <aside class="side-column">
        <section class="panel">
          <div class="panel-header-right">
            <h2 class="panel-title">Details</h2>
            <DownOutlined />
          </div>

          <div class="details-grid">
            <!-- Assignee -->
            <div class="field">
              <span class="label">Assignee</span>
              <a-space>
                <a-avatar size="small" style="background:#e0ecff">HH</a-avatar>
                <a-input v-model:value="assignee" size="small" style="width:160px" />
              </a-space>
            </div>

            <!-- Priority -->
            <div class="field">
              <span class="label">Priority</span>
              <a-dropdown trigger="click">
                <a-button size="small">
                  {{ priority }}
                  <DownOutlined />
                </a-button>
                <template #overlay>
                  <a-menu @click="({ key }) => setPriority(key)">
                    <a-menu-item v-for="p in priorityOptions" :key="p">{{ p }}</a-menu-item>
                  </a-menu>
                </template>
              </a-dropdown>
            </div>

            <!-- Due date -->
            <div class="field">
              <span class="label">Due date</span>
              <a-date-picker v-model:value="dueDate" style="width:100%" />
            </div>

            <!-- Labels -->
            <div class="field">
              <span class="label">Labels</span>
              <a-input v-model:value="labels" size="small" placeholder="None" />
            </div>

            <!-- Team -->
            <div class="field">
              <span class="label">Team</span>
              <a-input v-model:value="team" size="small" placeholder="None" />
            </div>

            <!-- Start date -->
            <div class="field">
              <span class="label">Start date</span>
              <a-date-picker v-model:value="startDate" style="width:100%" />
            </div>

            <!-- Reporter -->
            <div class="field">
              <span class="label">Reporter</span>
              <a-space>
                <a-avatar size="small" style="background:#e8ddff;color:#4338ca;">TN</a-avatar>
                <a-input v-model:value="reporter" size="small" style="width:160px" />
              </a-space>
            </div>
          </div>
        </section>
      </aside>
    </div>
  </div>
</template>

<script setup>
import {
  DownOutlined,
  EyeOutlined,
  CloseOutlined,
  MoreOutlined,
  PlusOutlined,
  SettingOutlined,
} from '@ant-design/icons-vue'
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { Editor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import Image from '@tiptap/extension-image'

/* ===== header issue status (same idea as bạn) ===== */
const issueStatus = ref('In Review')
const issueStatusOptions = [
  { value: 'To Do', label: 'TO DO' },
  { value: 'In Progress', label: 'IN PROGRESS' },
  { value: 'In Review', label: 'IN REVIEW' },
  { value: 'Done', label: 'DONE' },
]
const headerStatusLabel = computed(() => {
  const f = issueStatusOptions.find(o => o.value === issueStatus.value)
  return f ? f.label : issueStatus.value
})
const headerStatusClass = computed(() => {
  const s = issueStatus.value.toLowerCase()
  if (s === 'done') return 'issue-status--done'
  if (s === 'in progress') return 'issue-status--inprogress'
  if (s === 'in review') return 'issue-status--inreview'
  return 'issue-status--todo'
})
const headerDotClass = computed(() => {
  const s = issueStatus.value.toLowerCase()
  if (s === 'done') return 'dot-done'
  if (s === 'in progress') return 'dot-inprogress'
  if (s === 'in review') return 'dot-inreview'
  return 'dot-todo'
})
function onHeaderStatusClick({ key }) {
  const f = issueStatusOptions.find(o => o.value === key)
  issueStatus.value = f ? f.value : key
}

/* ===== Description tiptap ===== */
const description = ref('')
const editor = ref(null)
const isEditingDescription = ref(false)

function startEditDescription() {
  isEditingDescription.value = true
  if (!editor.value) {
    editor.value = new Editor({
      content: description.value || '<p></p>',
      extensions: [StarterKit, Link.configure({ openOnClick: false }), Image],
    })
  } else {
    editor.value.commands.setContent(description.value || '<p></p>', false)
  }
}
function saveDescription() {
  description.value = editor.value.getHTML()
  isEditingDescription.value = false
}
function cancelDescription() {
  isEditingDescription.value = false
}

/* ===== right panels ===== */
const assignee = ref('Huy Hoai')
const priority = ref('Medium')
const priorityOptions = ['Highest', 'High', 'Medium', 'Low', 'Lowest']
const labels = ref('')
const team = ref('')
const reporter = ref('Tuấn Kiệt Lê Nguyễn')
const dueDate = ref(null)
const startDate = ref(null)

function setPriority(p) {
  priority.value = p
}

/* ===== Subtasks ===== */
const showCreate = ref(false)
const subtasks = ref([
  { key: 'KAN-4', title: 'rrr', priority: 'Medium', assignee: 'Unassigned', status: 'Done' },
  { key: 'KAN-8', title: 'hhh', priority: 'Medium', assignee: 'Unassigned', status: 'In Progress' },
  { key: 'KAN-9', title: 'ds', priority: 'Medium', assignee: 'Unassigned', status: 'In Review' },
  { key: 'KAN-10', title: 'Design database schema for to-do items', priority: 'Medium', assignee: 'Unassigned', status: 'To Do' },
  { key: 'KAN-11', title: 'Write API for subtasks', priority: 'Medium', assignee: 'Unassigned', status: 'To Do' },
  { key: 'KAN-12', title: 'UI polish', priority: 'Medium', assignee: 'Unassigned', status: 'To Do' },
])
const newSubtask = ref({ title: '', priority: 'Medium' })

const subtaskColumns = [
  { title: 'Work', dataIndex: 'work' },
  { title: 'Priority', dataIndex: 'priority', width: 120 },
  { title: 'Assignee', dataIndex: 'assignee', width: 150 },
  { title: 'Status', dataIndex: 'status', width: 130 },
]

function addSubtask() {
  if (!newSubtask.value.title.trim()) return
  const key = 'KAN-' + (4 + subtasks.value.length + 1)
  subtasks.value.push({
    key,
    title: newSubtask.value.title,
    priority: newSubtask.value.priority,
    assignee: 'Unassigned',
    status: 'To Do',
  })
  newSubtask.value.title = ''
  showCreate.value = false
}

const statusOptions = [
  { value: 'To Do', label: 'TO DO', class: 'pill-todo' },
  { value: 'In Progress', label: 'IN PROGRESS', class: 'pill-inprogress' },
  { value: 'In Review', label: 'IN REVIEW', class: 'pill-inreview' },
  { value: 'Done', label: 'DONE', class: 'pill-done' },
]
function setSubtaskPriority(idx, p) {
  subtasks.value[idx].priority = p
}
function setTaskStatus(idx, v) {
  subtasks.value[idx].status = v
}
function displayStatus(v) {
  const f = statusOptions.find(o => o.value === v)
  return f ? f.label : v
}
function pillClass(status) {
  const s = (status || '').toLowerCase()
  if (s === 'done') return 'pill-done'
  if (s === 'in progress') return 'pill-inprogress'
  if (s === 'in review') return 'pill-inreview'
  return 'pill-todo'
}
const statusPercents = computed(() => {
  const total = subtasks.value.length || 1
  let done = 0, inProgress = 0, inReview = 0
  subtasks.value.forEach(t => {
    const s = (t.status || '').toLowerCase()
    if (s === 'done') done++
    else if (s === 'in progress') inProgress++
    else if (s === 'in review') inReview++
  })
  const donePct = (done / total) * 100
  const inProgPct = (inProgress / total) * 100
  const inRevPct = (inReview / total) * 100
  let todoPct = 100 - (donePct + inProgPct + inRevPct)
  if (todoPct < 0) todoPct = 0
  return { done: donePct, inProgress: inProgPct, inReview: inRevPct, todo: todoPct }
})

/* ===== Activity ===== */
const activityTabs = ['All', 'Comments', 'History']
const activeTab = ref('Comments')

const comments = ref([
  { id: 1, user: 'Huy Hoai', initials: 'HH', createdAt: Date.now() - 60_000, content: 'sdsd' },
  { id: 2, user: 'Huy Hoai', initials: 'HH', createdAt: Date.now() - 90_000, content: 'dsdsds' },
])
const mentionUsers = ref([
  { id: 'tn', name: 'Tuấn Kiệt Lê Nguyễn' },
  { id: 'hh', name: 'Huy Hoai' },
  { id: 'pm', name: 'Product Manager' },
])
const mentionOptions = computed(() =>
  mentionUsers.value.map(u => ({ value: '@' + u.name, label: u.name }))
)
const newComment = ref('')
function saveComment() {
  if (!newComment.value.trim()) return
  comments.value.unshift({
    id: Date.now(),
    user: 'Huy Hoai',
    initials: 'HH',
    createdAt: Date.now(),
    content: newComment.value.trim(),
  })
  newComment.value = ''
}
function cancelComment() {
  newComment.value = ''
}
function deleteComment(id) {
  comments.value = comments.value.filter(c => c.id !== id)
}

/* history fake */
const historyItems = ref([
  { id: 1, user: 'Tuấn Kiệt Lê Nguyễn', initials: 'TN', action: 'created the Work item', timeAgo: '3 hours ago', type: 'text' },
  { id: 2, user: 'Tuấn Kiệt Lê Nguyễn', initials: 'TN', action: 'changed the Status', timeAgo: '3 hours ago', type: 'status', from: 'TO DO', to: 'TO DO' },
  { id: 3, user: 'Tuấn Kiệt Lê Nguyễn', initials: 'TN', action: 'updated the Summary', timeAgo: '2 hours ago', type: 'text' },
])

/* timeago */
const now = ref(Date.now())
let timer = null
onMounted(() => {
  timer = setInterval(() => {
    now.value = Date.now()
  }, 30_000)
})
onBeforeUnmount(() => {
  if (timer) clearInterval(timer)
})
function formatTimeAgo(ts) {
  const diff = now.value - ts
  const sec = Math.floor(diff / 1000)
  if (sec < 60) return sec + 's ago'
  const min = Math.floor(sec / 60)
  if (min < 60) return min + 'm ago'
  const hr = Math.floor(min / 60)
  if (hr < 24) return hr + 'h ago'
  const day = Math.floor(hr / 24)
  return day + 'd ago'
}
</script>

<style scoped>
.issue-page {
  min-height: 100vh;
  background: #f3f4f6;
  display: flex;
  flex-direction: column;
}
.issue-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #fff;
  border-bottom: 1px solid #e5e7eb;
  padding: 1rem 1.5rem .7rem;
}
.issue-title {
  font-size: 1.5rem;
  font-weight: 600;
  margin-top: .35rem;
}
.right {
  display: flex;
  gap: .5rem;
  align-items: center;
}
.header-status {
  display: flex;
  align-items: center;
  gap: .4rem;
  border-radius: .5rem;
  font-size: .75rem;
}
.issue-status--todo { background: #e5e7eb; color: #111827; }
.issue-status--inprogress { background: #dbeafe; color: #1d4ed8; }
.issue-status--inreview { background: #e0ebff; color: #1f2937; }
.issue-status--done { background: #a7d28d; color: #1f2937; }
.status-dot { width: 7px; height: 7px; border-radius: 50%; }
.dot-todo { background: #6b7280; }
.dot-inprogress { background: #1d4ed8; }
.dot-inreview { background: #2563eb; }
.dot-done { background: #1a7f37; }

.issue-body {
  display: flex;
  gap: 1rem;
  padding: 1rem 1.5rem 2rem;
}
.main-column { flex: 1 1 68%; display: flex; flex-direction: column; gap: 1rem; }
.side-column { width: 20%; display: flex; flex-direction: column; gap: 1rem; }

.panel {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: .35rem;
  padding: 1rem;
}
.panel-title { font-weight: 600; font-size: .9rem; }
.panel-head { display:flex; justify-content:space-between; align-items:center; }

/* description */
.description-display,
.description-placeholder {
  padding: 6px 8px;
  cursor: pointer;
  border-radius: 4px;
}
.description-placeholder { color: #6b7280; }
.description-display:hover,
.description-placeholder:hover {
  background: #f9fafb;
}
.description-editor .editor-toolbar {
  display: flex;
  gap: 4px;
  margin-bottom: 6px;
}
.description-editor .editor-toolbar button {
  border: none;
  background: #f3f4f6;
  width: 26px;
  height: 26px;
  border-radius: 4px;
  cursor: pointer;
}
.description-editor .editor-toolbar button.active {
  background: #dbeafe;
}
.editor-body {
  border: 1px solid #e5e7eb;
  min-height: 120px;
  border-radius: 4px;
  padding: 6px;
  background: #fff;
}
.editor-actions {
  margin-top: 6px;
  display: flex;
  gap: 6px;
}

/* subtasks */
.subtasks-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: .6rem;
}
.progress-row {
  display: flex;
  gap: .6rem;
  align-items: center;
  margin-bottom: .6rem;
}
.progress-track {
  flex: 1;
  height: 7px;
  background: #e5e7eb;
  border-radius: 999px;
  overflow: hidden;
  display: flex;
}
.progress-seg { height: 100%; }
.progress-seg.done { background: #6a994e; }
.progress-seg.in-progress { background: #4b6cff; }
.progress-seg.in-review { background: #8b95ff; }
.progress-seg.todo { background: #d1d5db; }
.progress-label { font-size: .68rem; color: #6b7280; }
.create-row { display: flex; gap: .4rem; margin-bottom: .6rem; }
.issue-key { color: #2563eb; font-weight: 500; margin-right: .3rem; }
.priority-chip {
  background: #fff7e6;
  border: 1px solid #ffe7ba;
  border-radius: .4rem;
  padding: .1rem .45rem;
  font-size: .68rem;
  cursor: pointer;
  display: inline-flex;
  gap: 4px;
  align-items: center;
}
.status-pill {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  border-radius: .4rem;
  padding: .15rem .55rem .2rem;
  font-size: .63rem;
  font-weight: 600;
  cursor: pointer;
}
.pill-todo { background: #e5e7eb; color: #111827; }
.pill-inprogress { background: #dbeafe; color: #1d4ed8; }
.pill-inreview { background: #dbeafe; color: #1f3fa4; }
.pill-done { background: #d1fae5; color: #065f46; }

/* activity */
.activity-panel { max-height: 420px; overflow-y: auto; }
.panel-top-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: .4rem; }

.comment-item { display: flex; gap: .6rem; margin-bottom: 1rem; }
.comment-body { flex: 1; }
.comment-header { display: flex; gap: .5rem; align-items: center; }
.comment-name { font-weight: 600; font-size: .78rem; }
.comment-time { font-size: .65rem; color: #9ca3af; }
.comment-content { margin-top: .4rem; font-size: .78rem; line-height: 1.4; }
.comment-actions { display: flex; gap: .45rem; margin-top: .45rem; }

.comment-add { display: flex; gap: .6rem; margin-top: 1rem; }
.comment-editor { flex: 1; }
.comment-editor-actions { margin-top: .35rem; display: flex; gap: .35rem; }

.history-item { display: flex; gap: .6rem; margin-bottom: 1rem; }
.history-body { flex: 1; }
.history-row { display: flex; gap: .3rem; flex-wrap: wrap; font-size: .78rem; }
.history-name { font-weight: 600; }
.history-time { font-size: .65rem; color: #9ca3af; margin-bottom: .25rem; }
.history-change { display: flex; align-items: center; gap: .35rem; }
.history-arrow { font-size: .7rem; }

/* right side */
.panel-header-right { display: flex; justify-content: space-between; align-items: center; margin-bottom: .6rem; }
.details-grid { display: grid; gap: .65rem; }
.field { display: flex; flex-direction: column; gap: .3rem; }
.label { font-size: .6rem; text-transform: uppercase; color: #9ca3af; }
.right {
  display: flex;
  align-items: center;
  gap: 0.75rem; /* tách status và cụm icon */
}

.icon-buttons {
  display: flex;
  align-items: center;
  gap: 0.4rem;  /* tách từng nút */
}

/* để badge không đè lên nút bên cạnh */
.icon-buttons :deep(.ant-badge) {
  line-height: 1;             /* fix chiều cao */
}
.icon-buttons :deep(.ant-badge-wrapper) {
  display: inline-flex;
}
.issue-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;        /* <-- quan trọng: thiếu cái này là bể khi zoom */
}

/* tách rõ 2 bên để dễ control */
.issue-header .left {
  min-width: 0;           /* cho phép co khi chật */
}

.issue-header .right {
  display: flex;
  align-items: center;
  gap: .5rem;
  margin-left: auto;      /* khi đủ chỗ thì nằm bên phải */
  flex-wrap: wrap;        /* nếu vẫn chật thì các nút tự xuống dòng */
}
.issue-body {
  display: flex;
  gap: 1rem;
  min-width: 0;      /* để cha không đẩy rộng */
}

.main-column,
.side-column {
  min-width: 0;      /* cho phép co khi chật */
}

/* bảng subtasks nếu có text dài */
.subtasks-table {
  width: 100%;
  table-layout: fixed;
}

.subtasks-table td {
  word-break: break-word;
}

@media (max-width: 1280px) {
  .issue-header .right {
    width: 100%;
    justify-content: flex-end;
  }
}
</style>
