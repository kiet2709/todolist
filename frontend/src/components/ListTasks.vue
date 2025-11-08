<script setup>
import { ref, computed, watch } from 'vue'
import {
  CaretDownOutlined, CaretRightOutlined, PlusOutlined,
  FilterOutlined, EllipsisOutlined, LeftOutlined, RightOutlined,
  CalendarOutlined, DownOutlined, SearchOutlined
} from '@ant-design/icons-vue'
import {
  Dropdown as ADropdown, Button as AButton, Input as AInput,
  Select as ASelect, SelectOption as ASelectOption
} from 'ant-design-vue'

// Thêm state để kiểm soát dropdown
const filterOpen = ref(false)

// ---------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------
const rawTasks = ref([
  {
    id: 1, type: 'story', typeName: 'Story', key: 'KAN-5', title: 'Implement auth', status: 'IN REVIEW',
    assignee: { initials: 'HH', name: 'Huy Hoai' }, due: '2025-11-05', progress: 0,
    subtasks: [
      { id: 11, type: 'sub-task', typeName: 'Sub-task', key: 'KAN-5.1', title: 'Add login API', status: 'DONE', assignee: { initials: 'HH', name: 'Huy Hoai' }, due: '2025-11-04', progress: 100 },
      { id: 12, type: 'sub-task', typeName: 'Sub-task', key: 'KAN-5.2', title: 'Frontend login form', status: 'IN REVIEW', assignee: null, due: '2025-11-06', progress: 60 }
    ]
  },
  {
    id: 2, type: 'task', typeName: 'Task', key: 'KAN-1', title: 'Task 1', status: 'TO DO',
    assignee: { initials: 'HH', name: 'Huy Hoai' }, due: '2025-11-10', progress: 0,
    subtasks: [
      { id: 21, type: 'sub-task', typeName: 'Sub-task', key: 'KAN-1.1', title: 'Subtask 1.1', status: 'TO DO', assignee: null, due: null, progress: 0 }
    ]
  },
  {
    id: 3, type: 'bug', typeName: 'Bug', key: 'KAN-4', title: 'Fix crash', status: 'DONE', assignee: null, due: null, progress: 100, subtasks: []
  },
  {
    id: 4, type: 'bug', typeName: 'Bug', key: 'KAN-8', title: 'Edge case', status: 'TO DO', assignee: null, due: null, progress: 0, subtasks: []
  },
  {
    id: 5, type: 'task', typeName: 'Task', key: 'KAN-2', title: 'Task 2k', status: 'IN PROGRESS',
    assignee: { initials: 'TN', name: 'Tuấn Kiệt Lê Nguyễn' }, due: '2025-11-15', progress: 0,
    subtasks: [
      { id: 51, type: 'sub-task', typeName: 'Sub-task', key: 'KAN-2.1', title: 'Database migration', status: 'DONE', assignee: { initials: 'TN', name: 'Tuấn Kiệt' }, due: '2025-11-15', progress: 100 }
    ]
  },
  {
    id: 6, type: 'bug', typeName: 'Bug', key: 'KAN-6', title: 'aaa', status: 'TO DO', assignee: null, due: null, progress: 0, subtasks: []
  },
  {
    id: 7, type: 'task', typeName: 'Task', key: 'KAN-7', title: 'xxx', status: 'IN PROGRESS',
    assignee: { initials: 'TN', name: 'Tuấn Kiệt Lê Nguyễn' }, due: null, progress: 70, subtasks: []
  }
])

// ---------------------------------------------------------------
// UI state
// ---------------------------------------------------------------
const search = ref('')
const selected = ref(new Set())
const viewMode = ref('list')
const hoverRow = ref(null)
const draggedTaskId = ref(null) // <-- DÙNG ID THAY VÌ OBJECT
const expanded = ref(new Set())
const today = new Date()
const currentMonth = ref(new Date(today.getFullYear(), today.getMonth(), 1))

// Filter state
const filterType = ref([])
const filterStatus = ref([])
const filterAssignee = ref([])

// ---------------------------------------------------------------
// Helper: Tìm task theo ID (parent hoặc subtask)
// ---------------------------------------------------------------
const findTaskById = (id) => {
  const parent = rawTasks.value.find(t => t.id === id)
  if (parent) return { task: parent, parent: null }

  for (const p of rawTasks.value) {
    const sub = p.subtasks?.find(s => s.id === id)
    if (sub) return { task: sub, parent: p }
  }
  return null
}

// ---------------------------------------------------------------
// Toggle expand
// ---------------------------------------------------------------
const toggleExpand = (id) => {
  const s = new Set(expanded.value)
  s.has(id) ? s.delete(id) : s.add(id)
  expanded.value = s
}

// ---------------------------------------------------------------
// Auto calculate progress & auto-complete parent
// ---------------------------------------------------------------
const updateProgress = (task) => {
  if (!task.subtasks || task.subtasks.length === 0) {
    task.progress = task.status === 'DONE' ? 100 : 0
    return
  }
  task.subtasks.forEach(sub => updateProgress(sub))
  const completed = task.subtasks.filter(s => s.status === 'DONE').length
  const avg = task.subtasks.reduce((sum, s) => sum + s.progress, 0) / task.subtasks.length
  task.progress = Math.round(avg)
  if (completed === task.subtasks.length) {
    task.status = 'DONE'
    task.progress = 100
  } else if (task.status === 'DONE') {
    task.status = 'IN PROGRESS'
  }
}
watch(rawTasks, () => rawTasks.value.forEach(updateProgress), { deep: true })
rawTasks.value.forEach(updateProgress)

// ---------------------------------------------------------------
// Filtered Tasks
// ---------------------------------------------------------------
const filteredTasks = computed(() => {
  const term = search.value.toLowerCase()
  return rawTasks.value.filter(parent => {
    const matchesSearch = !term ||
      parent.key.toLowerCase().includes(term) ||
      parent.title.toLowerCase().includes(term)
    const matchesType = !filterType.value.length || filterType.value.includes(parent.type)
    const matchesStatus = !filterStatus.value.length || filterStatus.value.includes(parent.status)
    const matchesAssignee = !filterAssignee.value.length ||
      (parent.assignee && filterAssignee.value.includes(parent.assignee.name))
    return matchesSearch && matchesType && matchesStatus && matchesAssignee
  })
})

// ---------------------------------------------------------------
// List View
// ---------------------------------------------------------------
const allTasks = computed(() => {
  const term = search.value.toLowerCase()
  const result = []
  filteredTasks.value.forEach(parent => {
    const parentMatches = !term || parent.key.toLowerCase().includes(term) || parent.title.toLowerCase().includes(term)
    if (parentMatches) result.push({ ...parent, isSubtask: false })
    if (parent.subtasks?.length && expanded.value.has(parent.id)) {
      parent.subtasks.forEach(sub => {
        const subMatches = !term || sub.key.toLowerCase().includes(term) || sub.title.toLowerCase().includes(term)
        if (subMatches) result.push({ ...sub, isSubtask: true, parentId: parent.id, parentTitle: parent.title })
      })
    }
  })
  return result
})

// ---------------------------------------------------------------
// Board View
// ---------------------------------------------------------------
const boardColumns = computed(() => {
  const cols = { 'TO DO': [], 'IN PROGRESS': [], 'IN REVIEW': [], 'DONE': [] }
  filteredTasks.value.forEach(parent => {
    if (cols[parent.status]) cols[parent.status].push(parent)
  })
  return cols
})

// ---------------------------------------------------------------
// Calendar View
// ---------------------------------------------------------------
const formatKey = (d) => `${new Date(d).getFullYear()}-${String(new Date(d).getMonth() + 1).padStart(2, '0')}-${String(new Date(d).getDate()).padStart(2, '0')}`
const timelineDates = computed(() => {
  const map = {}
  filteredTasks.value.forEach(t => {
    const key = t.due ? formatKey(t.due) : 'no-due'
    if (!map[key]) map[key] = []
    map[key].push({ ...t, isSubtask: false })
    if (t.subtasks?.length && expanded.value.has(t.id)) {
      t.subtasks.forEach(s => {
        const k2 = s.due ? formatKey(s.due) : 'no-due'
        if (!map[k2]) map[k2] = []
        map[k2].push({ ...s, isSubtask: true, parentId: t.id, parentTitle: t.title })
      })
    }
  })
  return map
})
const monthMatrix = computed(() => {
  const start = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth(), 1)
  const startDay = start.getDay() || 7
  const offset = (startDay - 1 + 7) % 7
  const daysInMonth = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() + 1, 0).getDate()
  const prevMonthDays = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth(), 0).getDate()
  const cells = []
  for (let i = offset - 1; i >= 0; i--) {
    cells.push({ date: new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() - 1, prevMonthDays - i), inMonth: false })
  }
  for (let d = 1; d <= daysInMonth; d++) {
    cells.push({ date: new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth(), d), inMonth: true })
  }
  while (cells.length < 42) {
    const nextDay = cells.length - (offset + daysInMonth) + 1
    cells.push({ date: new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() + 1, nextDay), inMonth: false })
  }
  return cells
})
const tasksForDate = (date) => timelineDates.value[formatKey(date)] || []
const prevMonth = () => currentMonth.value = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() - 1, 1)
const nextMonth = () => currentMonth.value = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() + 1, 1)

// ---------------------------------------------------------------
// Selection & Create
// ---------------------------------------------------------------
const toggleSelect = id => {
  const s = new Set(selected.value)
  s.has(id) ? s.delete(id) : s.add(id)
  selected.value = s
}
const toggleSelectAll = () => {
  selected.value = selected.value.size === allTasks.value.length ? new Set() : new Set(allTasks.value.map(t => t.id))
}
const createTask = (afterId = null) => {
  const newTask = {
    id: Date.now(),
    type: 'task', typeName: 'Task',
    key: `KAN-${Date.now().toString().slice(-3)}`,
    title: 'New Task', status: 'TO DO', assignee: null, due: null, progress: 0, subtasks: []
  }
  if (afterId === null) rawTasks.value.push(newTask)
  else {
    const idx = rawTasks.value.findIndex(t => t.id === afterId)
    if (idx !== -1) rawTasks.value.splice(idx + 1, 0, newTask)
  }
  updateProgress(newTask)
}

// ---------------------------------------------------------------
// Status Update
// ---------------------------------------------------------------
const updateStatus = (task, newStatus) => {
  task.status = newStatus
  updateProgress(task)
  const parent = rawTasks.value.find(p => p.subtasks?.some(s => s.id === task.id))
  if (parent) updateProgress(parent)
}

// ---------------------------------------------------------------
// Drag & Drop - ĐÃ SỬA HOÀN TOÀN
// ---------------------------------------------------------------
const dragStart = (e, taskId) => {
  draggedTaskId.value = taskId
  e.dataTransfer.effectAllowed = 'move'
  e.dataTransfer.setData('text/plain', taskId)
  const card = e.target.closest('.card')
  if (card) card.style.opacity = '0.5'
}

const dragEnd = (e) => {
  const card = e.target.closest('.card')
  if (card) card.style.opacity = '1'
  draggedTaskId.value = null
}

const allowDrop = (e) => {
  e.preventDefault()
  e.currentTarget.classList.add('drag-over')
}

const leaveDrop = (e) => {
  e.currentTarget.classList.remove('drag-over')
}

const drop = (e, status) => {
  e.preventDefault()
  e.currentTarget.classList.remove('drag-over')

  const taskId = Number(e.dataTransfer.getData('text/plain'))
  if (!taskId || draggedTaskId.value !== taskId) return

  const result = findTaskById(taskId)
  if (!result) return

  const { task } = result
  if (task.status === status) return

  task.status = status
  updateStatus(task, status)
}

// ---------------------------------------------------------------
// Icons & Helpers
// ---------------------------------------------------------------
function icon(pathD, viewBox = '0 0 24 24') {
  return { template: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}" class="svg-icon"><path d="${pathD}"/></svg>` }
}
const Bell = icon('M15 17h5l-1.405-1.405C18.212 15.212 18 14.607 18 14V9c0-3.07-1.64-5.64-4.5-6.32V2a1 1 0 0 0-2 0v.68C8.64 3.36 7 5.93 7 9v5c0 .607-.212 1.212-.595 1.595L5 17h5m5 0v1a3 3 0 1 1-6 0v-1m6 0H9')
const Share = icon('M8 12h8m-4-4V4m0 16v-4m8-8l-3-3m-6 0l-3 3m12 6l-3 3m-6-6l-3-3')
const Heart = icon('M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z')
const Calendar = icon('M19 4h-1V3a1 1 0 0 0-2 0v1H8V3a1 1 0 0 0-2 0v1H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H5V9h14v11z')
const typeIcon = type => {
  const map = {
    story: icon('M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z'),
    task: icon('M9 12l2 2 4-4'),
    bug: icon('M15 9h-2V7h-2v2H9l-3 3v5h12v-5l-3-3z'),
    'sub-task': icon('M15 11H9V9h6v2zm0 4H9v-2h6v2zm4-8H5c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V9c0-1.1-.9-2-2-2z')
  }
  return map[type] || null
}
const avatarColor = i => i === 'HH' ? '#3b82f6' : '#8b5cf6'
const progressColorByStatus = (status) => {
  if (status === 'DONE') return '#10b981'
  if (status === 'IN REVIEW') return '#f59e0b'
  if (status === 'IN PROGRESS') return '#f97316'
  return '#ef4444'
}
const formatDate = d => new Date(d).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })

// Assignees & Options
const assignees = computed(() => {
  const set = new Set()
  rawTasks.value.forEach(t => {
    if (t.assignee) set.add(t.assignee.name)
    t.subtasks?.forEach(s => s.assignee && set.add(s.assignee.name))
  })
  return Array.from(set)
})
const typeOptions = [
  { label: 'Story', value: 'story' },
  { label: 'Task', value: 'task' },
  { label: 'Bug', value: 'bug' }
]
const statusOptions = [
  { label: 'TO DO', value: 'TO DO' },
  { label: 'IN PROGRESS', value: 'IN PROGRESS' },
  { label: 'IN REVIEW', value: 'IN REVIEW' },
  { label: 'DONE', value: 'DONE' }
]
</script>

<template>
<div class="container">
    <!-- Header -->
    <header class="header">
      <div class="title">
        <div class="logo">T</div>
        <h1>To Do List System</h1>
      </div>
      <div class="header-actions">
        <AButton type="text" size="small"><component :is="Bell" /></AButton>
        <AButton type="text" size="small"><component :is="Share" /></AButton>
        <AButton type="text" size="small"><component :is="Heart" /></AButton>
      </div>
    </header>

    <!-- Tabs -->
    <nav class="tabs">
      <a href="#" class="tab" :class="{ active: viewMode === 'list' }" @click.prevent="viewMode = 'list'">List</a>
      <a href="#" class="tab" :class="{ active: viewMode === 'board' }" @click.prevent="viewMode = 'board'">Board</a>
      <a href="#" class="tab" :class="{ active: viewMode === 'timeline' }" @click.prevent="viewMode = 'timeline'">Calendar</a>
    </nav>

    <!-- Toolbar -->
    <div class="toolbar">
      <div class="left">
        <div class="search-wrapper">
          <AInput
            v-model:value="search"
            placeholder="Search tasks..."
            class="search-input"
          >
            <template #prefix>
              <SearchOutlined class="search-icon" />
            </template>
          </AInput>
        </div>
        <ADropdown v-model:open="filterOpen" trigger="click" @click.stop>
          <AButton @click.stop>
            <FilterOutlined /> Filter <DownOutlined />
          </AButton>
          <template #overlay>
            <div class="filter-dropdown" @click.stop>
              <div class="filter-section">
                <strong>Type</strong>
                <ASelect
                  v-model:value="filterType"
                  mode="multiple"
                  placeholder="Select types"
                  :options="typeOptions"
                  style="width: 100%"
                  :max-tag-count="1"
                />
              </div>
              <div class="filter-section">
                <strong>Status</strong>
                <ASelect
                  v-model:value="filterStatus"
                  mode="multiple"
                  placeholder="Select statuses"
                  :options="statusOptions"
                  style="width: 100%"
                  :max-tag-count="1"
                />
              </div>
              <div class="filter-section" v-if="assignees.length">
                <strong>Assignee</strong>
                <ASelect
                  v-model:value="filterAssignee"
                  mode="multiple"
                  placeholder="Select assignees"
                  :options="assignees.map(a => ({ label: a, value: a }))"
                  style="width: 100%"
                  show-search
                  :filter-option="(input, option) => option.label.toLowerCase().includes(input.toLowerCase())"
                  :max-tag-count="1"
                />
              </div>
              <div class="filter-footer">
                <AButton type="link" size="small" @click="filterType = []; filterStatus = []; filterAssignee = []; filterOpen = false">
                  Clear all
                </AButton>
              </div>
            </div>
          </template>
        </ADropdown>
      </div>
      <div class="right">
        <AButton type="text" size="small"><EllipsisOutlined /></AButton>
      </div>
    </div>

    <!-- ==================== LIST VIEW ==================== -->
    <div v-if="viewMode === 'list'" class="table-wrapper">
      <div class="table-container">
        <table class="task-table">
          <thead>
            <tr>
              <th class="checkbox-col"><input type="checkbox" :checked="selected.size === allTasks.length" @change="toggleSelectAll" /></th>
              <th class="insert-col"></th>
              <th class="expand-col"></th>
              <th class="type-col">Type</th>
              <th class="key-col">Key</th>
              <th class="title-col">Title</th>
              <th class="status-col">Status</th>
              <th class="">Assignee</th>
              <th class="due-col">Due</th>
              <th class="progress-col">Progress</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="t in allTasks"
              :key="t.id"
              :class="{ selected: selected.has(t.id), subtask: t.isSubtask, hover: hoverRow === t.id }"
              @click="toggleSelect(t.id)"
              @mouseenter="hoverRow = t.id"
              @mouseleave="hoverRow = null"
            >
              <td class="checkbox-col"><input type="checkbox" :checked="selected.has(t.id)" @click.stop="toggleSelect(t.id)" /></td>
              
              <!-- Nút +: luôn tồn tại, ẩn bằng opacity -->
              <td class="insert-col">
                <AButton
                  v-if="!t.isSubtask"
                  type="text"
                  size="small"
                  class="insert-btn"
                  :class="{ 'visible': hoverRow === t.id }"
                  @click.stop="createTask(t.id)"
                >
                  <PlusOutlined />
                </AButton>
              </td>

              <td class="expand-col" v-if="!t.isSubtask && rawTasks.find(p => p.id === t.id)?.subtasks?.length">
                <button class="expand-btn" @click.stop="toggleExpand(t.id)">
                  <component :is="expanded.has(t.id) ? CaretDownOutlined : CaretRightOutlined" class="ant-caret" />
                </button>
              </td>
              <td v-else class="expand-col"></td>

              <td class="type-col">{{ t.typeName }}</td>
              <td class="key-col">{{ t.key }}</td>
              <td class="title-col" :style="{ paddingLeft: t.isSubtask ? '2rem' : '0' }">
                {{ t.isSubtask ? '↳ ' + t.title + ' (of ' + t.parentTitle + ')' : t.title }}
              </td>
              <td class="status-col">
                <ASelect :value="t.status" @change="val => updateStatus(t, val)" size="small" style="width: 110px">
                  <ASelectOption value="TO DO">TO DO</ASelectOption>
                  <ASelectOption value="IN PROGRESS">IN PROGRESS</ASelectOption>
                  <ASelectOption value="IN REVIEW">IN REVIEW</ASelectOption>
                  <ASelectOption value="DONE">DONE</ASelectOption>
                </ASelect>
              </td>
              <td class="assignee-col">
                <div class="assignee-inner">
                  <div v-if="t.assignee" class="avatar" :style="{ backgroundColor: avatarColor(t.assignee.initials) }">
                    {{ t.assignee.initials }}
                  </div>
                  <span class="assignee-name">{{ t.assignee?.name || 'Unassigned' }}</span>
                </div>
              </td>
              <td class="due-col">
                <template v-if="t.due"><component :is="Calendar" class="cal-icon" />{{ formatDate(t.due) }}</template>
              </td>
              <td class="progress-col">
                <div class="progress-inner">
                  <div class="progress-bar">
                    <div class="progress-fill" :style="{ width: t.progress + '%', backgroundColor: progressColorByStatus(t.status) }"></div>
                  </div>
                  <span class="progress-pct">{{ t.progress }}%</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="create-footer">
        <AButton type="link" @click="createTask()"><PlusOutlined /> Create Task</AButton>
      </div>
    </div>

    <!-- ==================== BOARD VIEW ==================== -->
    <div v-if="viewMode === 'board'" class="board">
      <div v-for="(tasks, status) in boardColumns" :key="status" class="column"
           @dragover="allowDrop" @dragleave="leaveDrop" @drop="drop($event, status)">
        <h3 class="column-title">{{ status }} ({{ tasks.length }})</h3>
        <div class="card-list">
          <template v-for="parent in tasks" :key="parent.id">
            <!-- Parent Card -->
            <div class="card parent-card" :class="{ selected: selected.has(parent.id) }" draggable="true"
                 @dragstart="dragStart($event, parent.id)" @dragend="dragEnd" @click="toggleSelect(parent.id)">
              <div class="card-header">
                <span class="card-key">{{ parent.key }}</span>
                <component :is="typeIcon(parent.type)" class="card-type-icon" />
              </div>
              <p class="card-title">{{ parent.title }}</p>
              <div class="card-footer">
                <div v-if="parent.assignee" class="avatar small" :style="{ backgroundColor: avatarColor(parent.assignee.initials) }">
                  {{ parent.assignee.initials }}
                </div>
                <span v-else class="unassigned small">Unassigned</span>
                <div class="progress-bar small">
                  <div class="progress-fill" :style="{ width: parent.progress + '%', backgroundColor: progressColorByStatus(parent.status) }"></div>
                </div>
                <span class="progress-pct small">{{ parent.progress }}%</span>
              </div>
              <button v-if="parent.subtasks?.length" class="expand-btn-card" @click.stop="toggleExpand(parent.id)">
                <component :is="expanded.has(parent.id) ? CaretDownOutlined : CaretRightOutlined" class="caret small" />
              </button>
            </div>

            <!-- Subtasks -->
            <div v-for="sub in parent.subtasks" v-if="expanded.has(parent.id)" :key="sub.id" class="card sub-card"
                 :class="{ selected: selected.has(sub.id) }" draggable="true"
                 @dragstart="dragStart($event, sub.id)" @dragend="dragEnd" @click="toggleSelect(sub.id)">
              <div class="card-header">
                <span class="card-key">{{ sub.key }}</span>
                <component :is="typeIcon(sub.type)" class="card-type-icon" />
              </div>
              <p class="card-title">↳ {{ sub.title }}</p>
              <div class="card-footer">
                <div v-if="sub.assignee" class="avatar small" :style="{ backgroundColor: avatarColor(sub.assignee.initials) }">
                  {{ sub.assignee.initials }}
                </div>
                <span v-else class="unassigned small">Unassigned</span>
                <div class="progress-bar small">
                  <div class="progress-fill" :style="{ width: sub.progress + '%', backgroundColor: progressColorByStatus(sub.status) }"></div>
                </div>
                <span class="progress-pct small">{{ sub.progress }}%</span>
              </div>
            </div>
          </template>
        </div>
      </div>
    </div>

    <!-- ==================== CALENDAR VIEW ==================== -->
    <div v-if="viewMode === 'timeline'" class="calendar-view">
      <div class="calendar-controls">
        <div class="nav-left">
          <AButton type="text" @click="prevMonth"><LeftOutlined /></AButton>
          <span class="month-title">{{ currentMonth.toLocaleString('default', { month: 'long', year: 'numeric' }) }}</span>
          <AButton type="text" @click="nextMonth"><RightOutlined /></AButton>
        </div>
        <AButton type="default" size="small" @click="currentMonth = new Date(today.getFullYear(), today.getMonth(), 1)">
          <CalendarOutlined /> Today
        </AButton>
      </div>

      <div class="calendar-header">
        <div class="day-name">Mon</div>
        <div class="day-name">Tue</div>
        <div class="day-name">Wed</div>
        <div class="day-name">Thu</div>
        <div class="day-name">Fri</div>
        <div class="day-name">Sat</div>
        <div class="day-name">Sun</div>
      </div>

      <div class="calendar-grid">
        <div v-for="(cell, idx) in monthMatrix" :key="idx" class="calendar-day" :class="{ 'not-in-month': !cell.inMonth }">
          <div class="day-header">{{ cell.date.getDate() }}</div>
          <div class="day-tasks">
            <div v-for="task in tasksForDate(cell.date)" :key="task.id" class="day-task-item" :class="{ sub: task.isSubtask }">
              <div v-if="task.assignee" class="avatar small" :style="{ backgroundColor: avatarColor(task.assignee.initials) }">
                {{ task.assignee.initials }}
              </div>
              <div class="task-text">
                {{ task.key }} — {{ task.title }}
                <span v-if="task.isSubtask" class="parent-hint">(of {{ task.parentTitle }})</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
/* [TẤT CẢ CSS GỐC CỦA BẠN - KHÔNG THAY ĐỔI] */
.container { padding: 1rem; background: #fff; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,.1); min-height: 100vh; }
.header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; }
.title { display: flex; align-items: center; gap: .5rem; }
.logo { width: 32px; height: 32px; background: #2563eb; color: #fff; border-radius: 4px; font-weight: bold; display: flex; align-items: center; justify-content: center; }
h1 { margin: 0; font-size: 1.25rem; }

.tabs { display: flex; gap: 1.5rem; border-bottom: 1px solid #e5e7eb; margin-bottom: 1rem; }
.tab { padding: .5rem 0; color: #6b7280; font-size: .875rem; text-decoration: none; }
.tab.active { color: #2563eb; border-bottom: 2px solid #2563eb; font-weight: 600; }

.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: .75rem; }
.left { display: flex; align-items: center; gap: .5rem; }
.search-input { width: 240px; }
.filter-dropdown { width: 260px; padding: 12px; background: white; border-radius: 6px; box-shadow: 0 4px 12px rgba(0,0,0,.1); }
.filter-section { margin-bottom: 12px; }
.filter-section strong { display: block; margin-bottom: 6px; font-size: 0.8rem; color: #374151; }
.filter-footer { text-align: right; border-top: 1px solid #e5e7eb; padding-top: 8px; }

.search-wrapper {
  display: inline-block;
}
.search-input {
  width: 240px;
}

.table-wrapper { border: 1px solid #e5e7eb; border-radius: 6px; overflow: auto; max-height: 520px; }
.task-table { width: 100%; min-width: 1100px; border-collapse: collapse; font-size: .875rem; }
.task-table th { background: #f9fafb; text-align: left; padding: .5rem .75rem; font-weight: 600; border-bottom: 1px solid #e5e7eb; position: sticky; top: 0; z-index: 10; }
.task-table td { padding: .5rem .75rem; border-bottom: 1px solid #e5e7eb; }
.task-table tr:hover { background: #f9fafb; }
.task-table tr.selected { background: #dbeafe; }
.task-table tr.subtask { background: #f8fafc; }

.checkbox-col { width: 40px; text-align: center; }
.insert-col {
  width: 36px;
  position: relative;
}
.insert-btn {
  width: 28px;
  height: 28px;
  padding: 0;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.2s ease;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
}
.insert-btn.visible {
  opacity: 1;
  pointer-events: auto;
}
.insert-btn:hover {
  background-color: #dbeafe;
}
.expand-col { width: 36px; text-align: center; }
.type-col { width: 90px; }
.key-col { width: 110px; }
.title-col { min-width: 260px; }
.status-col { width: 140px; }
.assignee-col { width: 180px; }
.due-col { width: 120px; }
.progress-col { width: 140px; }

.assignee-col {
  width: 200px;
  font-size: .75rem;
}
.assignee-inner {
  display: flex;
  align-items: center;
  gap: .4rem;
}

.progress-col {
  width: 200px;
  font-size: .75rem;
}
.progress-inner {
  display: flex;
  align-items: center;
  gap: .4rem;
}
.avatar {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  color: white;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
}
.unassigned {
  color: #9ca3af;
}

.insert-btn { width: 100%; height: 100%; background: #dbeafe; border: none; color: #2563eb; font-weight: bold; cursor: pointer; }
.expand-btn { background: none; border: none; width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; }
.ant-caret { width: 16px; height: 16px; color: #6b7280; }

.avatar { width: 28px; height: 28px; border-radius: 50%; color: #fff; font-weight: 600; font-size: .7rem; display: flex; align-items: center; justify-content: center; }
.avatar.small { width: 20px; height: 20px; font-size: .65rem; }
.assignee-name { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 100px; }

.progress-bar { flex: 1; height: 8px; background: #e5e7eb; border-radius: 4px; overflow: hidden; }
.progress-bar.small { height: 6px; }
.progress-fill { height: 100%; transition: width .3s ease; }
.progress-pct { width: 36px; text-align: right; font-size: .75rem; color: #4b5563; }

.create-footer { padding: .75rem; border-top: 1px solid #e5e7eb; text-align: center; }

/* Board */
.board {
  display: flex;
  gap: 1rem;
  padding: 1rem 0;
  width: 100%;
  height: 500px;
  overflow-x: hidden;
  overflow-y: auto;
}

.column {
  flex: 1; /* chia đều chiều rộng */
  background: #f1f5f9;
  border-radius: 8px;
  padding: .75rem;
  display: flex;
  flex-direction: column;
  min-width: 0; /* rất quan trọng để flex co giãn đúng */
}
.column-title { margin: 0 0 .75rem; font-size: .9rem; font-weight: 600; color: #475569; }
.card-list { flex: 1; display: flex; flex-direction: column; gap: .5rem; overflow-y: auto; }
.card { background: #fff; border: 1px solid #e2e8f0; border-radius: 6px; padding: .75rem; cursor: grab; box-shadow: 0 1px 2px rgba(0,0,0,.05); position: relative; }
.card:active { cursor: grabbing; }
.card.selected { border-color: #3b82f6; background: #eff6ff; }
.sub-card { margin-left: 1.5rem; border-left: 3px solid #dbeafe; }
.card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: .5rem; }
.card-key { font-weight: 600; font-size: .8rem; color: #1e40af; }
.card-type-icon { width: 18px; height: 18px; }
.card-title { margin: 0; font-size: .875rem; }
.card-footer { display: flex; align-items: center; gap: .5rem; font-size: .75rem; }
.expand-btn-card { position: absolute; top: .4rem; right: .4rem; background: none; border: none; cursor: pointer; }

/* Calendar */
.calendar-view { height: 520px; display: flex; flex-direction: column; overflow-y: auto; }
.calendar-controls { display: flex; justify-content: space-between; align-items: center; margin-bottom: .75rem; flex-shrink: 0; }
.nav-left { display: flex; align-items: center; gap: .5rem; }
.month-title { font-weight: 600; min-width: 140px; text-align: center; }
.calendar-header { display: grid; grid-template-columns: repeat(7, 1fr); text-align: center; font-weight: 600; color: #475569; margin-bottom: .25rem; }
.day-name { padding: .5rem 0; font-size: .875rem; }
.calendar-grid { display: grid; grid-template-columns: repeat(7, 1fr); grid-auto-rows: 1fr; gap: .5rem; flex: 1; }
.calendar-day { border: 1px solid #e5e7eb; border-radius: 6px; background: #fff; padding: .5rem; display: flex; flex-direction: column; overflow: hidden; }
.not-in-month { background: #fbfdff; opacity: 0.6; }
.day-header { font-size: .75rem; font-weight: 600; color: #6b7280; margin-bottom: .25rem; text-align: right; }
.day-tasks { flex: 1; overflow-y: auto; font-size: .7rem; }
.day-task-item { display: flex; align-items: center; gap: .25rem; margin-bottom: .125rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.day-task-item.sub { padding-left: 1.2rem; color: #6b7280; }
.task-text { flex: 1; overflow: hidden; text-overflow: ellipsis; }
.parent-hint { font-size: .6rem; color: #9ca3af; }

/* Icons */
.svg-icon { width: 18px; height: 18px; fill: currentColor; }
.cal-icon { width: 14px; height: 14px; fill: #6b7280; margin-right: .2rem; }

/* THÊM 1 DÒNG NHỎ CHO DRAG FEEDBACK */
.column.drag-over { background: #dbeafe !important; }
</style>