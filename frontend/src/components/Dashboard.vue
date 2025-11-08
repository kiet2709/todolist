<template>
  <div class="kan-summary-page">
    <div class="kan-inner">
      <!-- TOP FILTER BAR -->
      <div class="top-bar">
        <!-- luôn có div này để giữ layout -->
        <div class="active-filters">
          <a-tag
            v-for="chip in activeFilterChips"
            :key="chip.key"
            closable
            @close="removeFilter(chip.key)"
          >
            {{ chip.label }}
          </a-tag>
        </div>

        <div class="filter-trigger">
          <a-dropdown v-model:open="filterOpen" trigger="click">
            <a-button>
              <FilterOutlined />
              Filter
            </a-button>
            <template #overlay>
              <div class="filter-panel-big">
                <div class="filter-title">Filters</div>

                <!-- Assignee -->
                <div class="filter-block">
                  <div class="label">Assignee</div>
                  <a-select
                    v-model:value="filterValues.assignee"
                    mode="multiple"
                    allow-clear
                    style="width: 100%;"
                    placeholder="Select assignees"
                  >
                    <a-select-option value="Huy Hoai">Huy Hoai</a-select-option>
                    <a-select-option value="Tuấn Kiệt">Tuấn Kiệt</a-select-option>
                    <a-select-option value="Unassigned">Unassigned</a-select-option>
                  </a-select>
                </div>

                <!-- Status -->
                <div class="filter-block">
                  <div class="label">Status</div>
                  <a-select
                    v-model:value="filterValues.status"
                    mode="multiple"
                    allow-clear
                    style="width: 100%;"
                    placeholder="Select status"
                  >
                    <a-select-option value="todo">To Do</a-select-option>
                    <a-select-option value="in-progress">In Progress</a-select-option>
                    <a-select-option value="in-review">In Review</a-select-option>
                    <a-select-option value="done">Done</a-select-option>
                  </a-select>
                </div>

                <!-- Priority -->
                <div class="filter-block">
                  <div class="label">Priority</div>
                  <a-select
                    v-model:value="filterValues.priority"
                    mode="multiple"
                    allow-clear
                    style="width: 100%;"
                    placeholder="Select priority"
                  >
                    <a-select-option value="highest">Highest</a-select-option>
                    <a-select-option value="high">High</a-select-option>
                    <a-select-option value="medium">Medium</a-select-option>
                    <a-select-option value="low">Low</a-select-option>
                    <a-select-option value="none">None</a-select-option>
                  </a-select>
                </div>

                <!-- Work type -->
                <div class="filter-block">
                  <div class="label">Work type</div>
                  <a-select
                    v-model:value="filterValues.workType"
                    mode="multiple"
                    allow-clear
                    style="width: 100%;"
                    placeholder="Select work types"
                  >
                    <a-select-option value="task">Task</a-select-option>
                    <a-select-option value="subtask">Subtask</a-select-option>
                    <a-select-option value="story">Story</a-select-option>
                    <a-select-option value="epic">Epic</a-select-option>
                    <a-select-option value="request">Request</a-select-option>
                  </a-select>
                </div>

                <a-divider style="margin: 10px 0;" />
                <a-button type="primary" block @click="filterOpen = false">
                  Apply
                </a-button>
              </div>
            </template>
          </a-dropdown>
        </div>
      </div>

      <!-- STAT CARDS -->
        <div class="stat-row">
        <div class="stat-card">
            <div class="stat-icon-box">
            <CheckCircleOutlined />
            </div>
            <div class="stat-text">
            <div class="stat-line">
                <span class="stat-number">{{ completedLast7 }}</span>
                <span class="stat-label-inline">completed</span>
            </div>
            <div class="stat-sub">in the last 7 days</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon-box">
            <EditOutlined />
            </div>
            <div class="stat-text">
            <div class="stat-line">
                <span class="stat-number">{{ updatedLast7 }}</span>
                <span class="stat-label-inline">updated</span>
            </div>
            <div class="stat-sub">in the last 7 days</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon-box">
            <CheckSquareOutlined />
            </div>
            <div class="stat-text">
            <div class="stat-line">
                <span class="stat-number">{{ createdLast7 }}</span>
                <span class="stat-label-inline">created</span>
            </div>
            <div class="stat-sub">in the last 7 days</div>
            </div>
        </div>

        <div class="stat-card">
            <div class="stat-icon-box">
            <CalendarOutlined />
            </div>
            <div class="stat-text">
            <div class="stat-line">
                <span class="stat-number">{{ dueSoon }}</span>
                <span class="stat-label-inline">due soon</span>
            </div>
            <div class="stat-sub">in the next 7 days</div>
            </div>
        </div>
        </div>


      <!-- STATUS OVERVIEW + RECENT ACTIVITY -->
      <div class="main-row">
        <a-card class="status-card" :bordered="false">
          <div class="card-title-line">
            <div>
              <div class="card-title">Status overview</div>
              <div class="card-sub">Get a snapshot of the status of your work items.</div>
            </div>
            <a-button type="link" size="small">View all work items</a-button>
          </div>

          <div class="status-content">
            <div class="donut-wrapper">
                <div class="donut" :style="donutStyle">
                    <div class="donut-center">{{ filteredTasks.length }}</div>
                    <div class="donut-center-text">Total work items</div>
                </div>

              <ul class="legend">
                <li>
                  <span class="dot dot-done"></span> Done: {{ countByStatus('done') }}
                </li>
                <li>
                  <span class="dot dot-progress"></span> In Progress: {{ countByStatus('in-progress') }}
                </li>
                <li>
                  <span class="dot dot-review"></span> In Review: {{ countByStatus('in-review') }}
                </li>
                <li>
                  <span class="dot dot-todo"></span> To Do: {{ countByStatus('todo') }}
                </li>
              </ul>
            </div>
          </div>
        </a-card>

        <a-card class="activity-card" :bordered="false">
          <div class="card-title">Recent activity</div>
          <div class="card-sub">
            Stay up to date with what's happening across the space.
          </div>

          <div class="activity-list">
            <div
              v-for="act in recentActivity"
              :key="act.id"
              class="activity-item"
            >
              <div class="avatar">{{ act.userInitials }}</div>
              
              <div class="activity-info">                  
                <a-tag v-if="act.status" size="small" :color="statusTagColor(act.status)">
                    {{ act.statusLabel }}
                </a-tag>
                <div class="text">
                  <span class="user">{{ act.user }}</span>
                  
                  {{ act.action }}
                  <a class="item-link">{{ act.item }}</a>

                </div>
                <div class="time">{{ act.timeAgo }}</div>
              </div>
            </div>
          </div>
        </a-card>
      </div>

      <!-- BOTTOM ROW -->
      <div class="bottom-row">
        <!-- Priority breakdown -->
        <a-card class="bottom-card" :bordered="false">
          <div class="card-title-line">
            <div>
              <div class="card-title">Priority breakdown</div>
              <div class="card-sub">Get a holistic view of how work is being prioritized.</div>
            </div>
          </div>
          <div class="priority-bars">
            <div class="prio-row" v-for="p in priorityOrder" :key="p.key">
              <div class="prio-label">
                <span :class="['prio-icon', 'prio-' + p.key]"></span>
                {{ p.label }}
              </div>
              <div class="prio-bar-wrap">
                <div class="prio-bar" :style="{ width: priorityPercent(p.key) + '%' }"></div>
              </div>
              <div class="prio-num">{{ countByPriority(p.key) }}</div>
            </div>
          </div>
        </a-card>

        <!-- Types of work -->
        <a-card class="bottom-card" :bordered="false">
          <div class="card-title-line">
            <div>
              <div class="card-title">Types of work</div>
              <div class="card-sub">Get a breakdown of work items by their types.</div>
            </div>
            
          </div>
          <div class="types-list">
            <div class="type-row" v-for="t in workTypes" :key="t.key">
              <div class="type-name">
                <component :is="t.icon" style="margin-right: 6px;" />
                {{ t.label }}
              </div>
              <div class="type-bar-wrap">
                <div class="type-bar" :style="{ width: workTypePercent(t.key) + '%' }"></div>
              </div>
              <div class="type-perc">{{ workTypePercent(t.key) }}%</div>
            </div>
          </div>
        </a-card>

        <!-- Team workload -->
        <a-card class="bottom-card" :bordered="false">
          <div class="card-title">Team workload</div>
          <div class="card-sub">
            Monitor the capacity of your team.
            <!-- <a-button type="link" size="small">Reassign work items to get the right balance</a-button> -->
          </div>
          <div class="team-list">
            <div class="team-row" v-for="m in teamWorkload" :key="m.name">
              <div class="team-name">
                <div class="avatar small">{{ m.initials }}</div>
                {{ m.name }}
              </div>
              <div class="team-bar-wrap">
                <div class="team-bar" :style="{ width: m.percent + '%' }"></div>
              </div>
              <div class="team-perc">{{ m.percent }}%</div>
            </div>
          </div>
        </a-card>

        <!-- Epic progress -->
        <a-card class="bottom-card epic-card" :bordered="false">
          <div class="empty-epic">
            <div class="icon-box">🧩</div>
            <div class="title">Epic progress</div>
            <div class="sub">
              Use epics to track larger initiatives in your space.
              <a-button type="link" size="small">What is an epic?</a-button>
            </div>
          </div>
        </a-card>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, reactive, ref } from 'vue'
import {
  FilterOutlined,
  CheckCircleOutlined,
  EditOutlined,
  CheckSquareOutlined,
  CalendarOutlined,
  PaperClipOutlined,
  ApartmentOutlined,
  ThunderboltOutlined,
  PlusSquareOutlined,
} from '@ant-design/icons-vue'

// giả dữ liệu task
const tasks = ref([
  {
    id: 'KAN-1',
    title: 'Task 1',
    status: 'todo',
    priority: 'medium',
    workType: 'task',
    assignee: 'Huy Hoai',
    createdAt: daysAgo(2),
    updatedAt: daysAgo(1),
    dueDate: daysFromNow(5),
  },
  {
    id: 'KAN-2',
    title: 'Task 2k',
    status: 'in-progress',
    priority: 'highest',
    workType: 'task',
    assignee: 'Tuấn Kiệt',
    createdAt: daysAgo(3),
    updatedAt: daysAgo(1),
    dueDate: daysFromNow(10),
  },
  {
    id: 'KAN-3',
    title: 'Setup factory monitor',
    status: 'done',
    priority: 'low',
    workType: 'story',
    assignee: 'Unassigned',
    createdAt: daysAgo(6),
    updatedAt: daysAgo(4),
    dueDate: daysFromNow(1),
  },
  {
    id: 'KAN-4',
    title: 'Fix EMS login',
    status: 'in-review',
    priority: 'medium',
    workType: 'subtask',
    assignee: 'Huy Hoai',
    createdAt: daysAgo(1),
    updatedAt: daysAgo(1),
    dueDate: daysFromNow(2),
  },
  {
    id: 'KAN-5',
    title: 'Add translation zh-TW',
    status: 'todo',
    priority: 'medium',
    workType: 'task',
    assignee: 'Unassigned',
    createdAt: daysAgo(7),
    updatedAt: daysAgo(7),
    dueDate: daysFromNow(15),
  },
])

const filterOpen = ref(false)

// giá trị filter
const filterValues = reactive({
  assignee: [],
  status: [],
  priority: [],
  workType: [],
})

// hoạt động gần đây (giả)
const recentActivity = ref([
  {
    id: 1,
    user: 'Huy Hoai',
    userInitials: 'HH',
    action: 'updated field "duedate" on',
    item: 'KAN-1: Task 1',
    status: 'todo',
    statusLabel: 'TO DO',
    timeAgo: 'about 24 hours ago',
  },
  {
    id: 2,
    user: 'Huy Hoai',
    userInitials: 'HH',
    action: 'changed the Priority from ▭ to ⬆ Highest on',
    item: 'KAN-1: Task 1',
    status: 'todo',
    statusLabel: 'TO DO',
    timeAgo: 'about 24 hours ago',
  },
  {
    id: 3,
    user: 'Tuấn Kiệt Lê Nguyễn',
    userInitials: 'TN',
    action: 'updated field "status" on',
    item: 'KAN-2: Task 2k',
    status: 'in-progress',
    statusLabel: 'IN PROGRESS',
    timeAgo: 'about 24 hours ago',
  },
])

// work types list
const workTypes = [
  { key: 'subtask', label: 'Subtask', icon: PaperClipOutlined },
  { key: 'task', label: 'Task', icon: CheckSquareOutlined },
  { key: 'story', label: 'Story', icon: ApartmentOutlined },
  { key: 'epic', label: 'Epic', icon: ThunderboltOutlined },
  { key: 'request', label: 'Request', icon: PlusSquareOutlined },
]

// team workload (giả)
const teamWorkload = [
  { name: 'Unassigned', initials: 'U', percent: 57 },
  { name: 'Huy Hoai', initials: 'HH', percent: 21 },
  { name: 'Tuấn Kiệt Lê Nguyen', initials: 'TN', percent: 21 },
]

// thứ tự ưu tiên
const priorityOrder = [
  { key: 'highest', label: 'Highest' },
  { key: 'high', label: 'High' },
  { key: 'medium', label: 'Medium' },
  { key: 'low', label: 'Low' },
  { key: 'none', label: 'None' },
]

// tasks sau khi lọc
const filteredTasks = computed(() => {
  return tasks.value.filter((t) => {
    if (filterValues.assignee.length && !filterValues.assignee.includes(t.assignee)) return false
    if (filterValues.status.length && !filterValues.status.includes(t.status)) return false
    if (filterValues.priority.length && !filterValues.priority.includes(t.priority)) return false
    if (filterValues.workType.length && !filterValues.workType.includes(t.workType)) return false
    return true
  })
})

// top stats
const completedLast7 = computed(() =>
  filteredTasks.value.filter(
    (t) => t.status === 'done' && isWithinDays(t.updatedAt, 7)
  ).length
)
const updatedLast7 = computed(() =>
  filteredTasks.value.filter((t) => isWithinDays(t.updatedAt, 7)).length
)
const createdLast7 = computed(() =>
  filteredTasks.value.filter((t) => isWithinDays(t.createdAt, 7)).length
)
const dueSoon = computed(() =>
  filteredTasks.value.filter((t) => isWithinNextDays(t.dueDate, 7)).length
)

// chips
const activeFilterChips = computed(() => {
  const chips = []
  if (filterValues.assignee.length) {
    chips.push({ key: 'assignee', label: 'Assignee: ' + filterValues.assignee.join(', ') })
  }
  if (filterValues.status.length) {
    chips.push({ key: 'status', label: 'Status: ' + filterValues.status.join(', ') })
  }
  if (filterValues.priority.length) {
    chips.push({ key: 'priority', label: 'Priority: ' + filterValues.priority.join(', ') })
  }
  if (filterValues.workType.length) {
    chips.push({ key: 'workType', label: 'Work type: ' + filterValues.workType.join(', ') })
  }
  return chips
})

function removeFilter(key) {
  filterValues[key] = []
}

// helpers
function daysAgo(n) {
  const d = new Date()
  d.setDate(d.getDate() - n)
  return d.toISOString()
}
function daysFromNow(n) {
  const d = new Date()
  d.setDate(d.getDate() + n)
  return d.toISOString()
}
function isWithinDays(dateStr, days) {
  const target = new Date(dateStr)
  const now = new Date()
  const diff = (now - target) / (1000 * 60 * 60 * 24)
  return diff <= days
}
function isWithinNextDays(dateStr, days) {
  const target = new Date(dateStr)
  const now = new Date()
  const diff = (target - now) / (1000 * 60 * 60 * 24)
  return diff >= 0 && diff <= days
}

function countByStatus(st) {
  return filteredTasks.value.filter((t) => t.status === st).length
}
function countByPriority(p) {
  return filteredTasks.value.filter((t) => t.priority === p).length
}
function priorityPercent(p) {
  const total = filteredTasks.value.length || 1
  return Math.round((countByPriority(p) / total) * 100)
}
function workTypePercent(k) {
  const total = filteredTasks.value.length || 1
  const cnt = filteredTasks.value.filter((t) => t.workType === k).length
  return Math.round((cnt / total) * 100)
}
function statusTagColor(st) {
  if (st === 'todo') return 'blue'
  if (st === 'in-progress') return 'purple'
  if (st === 'in-review') return 'orange'
  if (st === 'done') return 'green'
  return 'default'
}

const donutStyle = computed(() => {
  const done = countByStatus('done')
  const inProgress = countByStatus('in-progress')
  const inReview = countByStatus('in-review')
  const todo = countByStatus('todo')

  const total = done + inProgress + inReview + todo

  // tránh chia 0
  if (total === 0) {
    return {
      background: '#e5e7eb'
    }
  }

  // chuyển số -> góc
  const doneDeg = (done / total) * 360
  const inProgressDeg = (inProgress / total) * 360
  const inReviewDeg = (inReview / total) * 360
  const todoDeg = (todo / total) * 360

  // tính điểm dừng
  const p1 = doneDeg
  const p2 = p1 + inProgressDeg
  const p3 = p2 + inReviewDeg
  const p4 = 360 // hết vòng

  // màu giống hình của bạn
  const doneColor = '#4b7bd6'       // xanh dương
  const inProgressColor = '#7fb659' // xanh lá
  const inReviewColor = '#b079e3'   // tím
  const todoColor = '#d58a30'       // cam

  return {
    background: `conic-gradient(
      ${doneColor} 0deg ${p1}deg,
      ${inProgressColor} ${p1}deg ${p2}deg,
      ${inReviewColor} ${p2}deg ${p3}deg,
      ${todoColor} ${p3}deg ${p4}deg
    )`
  }
})

</script>

<style scoped>
.kan-summary-page {
  background: #f4f5f7;
  min-height: 100vh;
}
.kan-inner {
  max-width: 1280px;
  margin: 0 auto;
  padding: 16px 16px 38px;
}

/* top bar */
.top-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}
.active-filters {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  flex: 1;
}
.filter-trigger {
  margin-left: auto;
}
.filter-panel-big {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  padding: 10px;
  width: 260px;
}
.filter-block {
  margin-bottom: 8px;
}
.filter-block .label {
  font-size: 12px;
  margin-bottom: 4px;
  color: #374151;
}

/* stat cards */
.stat-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
  gap: 16px;
  margin-bottom: 16px;
}

.stat-card {
  display: flex;
  gap: 12px;
  align-items: center;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 14px 16px;
  min-height: 70px;
}

.stat-icon-box {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: #f3f4f6;
  display: grid;
  place-items: center;
  font-size: 20px;
  color: #4b5563;
}

.stat-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stat-line {
  display: flex;
  gap: 4px;
  align-items: baseline;
}

.stat-number {
  font-size: 16px;
  font-weight: 600;
  color: #111827;
  gap: 4px;
}

.stat-label-inline {
  font-size: 14px;
  font-weight: 600;
  color: #111827;
}

.stat-sub {
  font-size: 12px;
  color: #6b7280;
}


/* main row */
.main-row {
  display: grid;
  grid-template-columns: minmax(0, 1.5fr) minmax(320px, 2fr);
  gap: 16px;
  margin-bottom: 16px;
}
.status-card,
.activity-card {
  border-radius: 18px;
  background: #fff;
}
.card-title-line {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}
.card-title {
  font-weight: 600;
}
.card-sub {
  font-size: 12px;
  color: #6b7280;
  margin-top: 4px;
}

/* status content */
.status-content {
  display: flex;
  align-items: center;
  padding: 16px;
}

.donut-wrapper {
  display: flex;
  gap: 24px;
  align-items: center;
  width: 100%;
}
.donut {
  width: 180px;
  height: 180px;
  border-radius: 9999px;
  position: relative;
  display: grid;
  place-items: center;
}

/* cái vòng trắng ở giữa */
.donut::after {
  content: '';
  width: 100px;
  height: 100px;
  background: #fff;
  border-radius: 9999px;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

/* số ở giữa */
.donut-center {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 26px;
  font-weight: 700;
  color: #2d2f33;
}

/* dòng chữ dưới số */
.donut-center-text {
  position: absolute;
  top: calc(50% + 26px); /* đẩy xuống dưới con số một chút */
  left: 50%;
  transform: translateX(-50%);
  font-size: 10px;
  color: #6b7280;
  white-space: nowrap;
}

.legend {
  list-style: none;
  padding: 0;
  margin: 0;
}
.legend li {
  display: flex;
  gap: 6px;
  align-items: center;
  margin-bottom: 6px;
  font-size: 12px;
}
.dot {
  width: 10px;
  height: 10px;
  border-radius: 9999px;
}
.dot-done {
  background: #3b82f6;
}
.dot-progress {
  background: #22c55e;
}
.dot-review {
  background: #8b5cf6;
}
.dot-todo {
  background: #f97316;
}

/* activity */
.activity-list {
  max-height: 240px;
  overflow-y: auto;
  margin-top: 12px;
}
.activity-item {
  display: flex;
  gap: 10px;
  margin-bottom: 12px;
}
.avatar {
  width: 36px;
  height: 36px;
  border-radius: 9999px;
  background: #0ea5e9;
  color: #fff;
  display: grid;
  place-items: center;
  font-weight: 600;
}
.avatar.small {
  width: 28px;
  height: 28px;
  font-size: 12px;
}
.activity-info .text {
  font-size: 13px;
}
.activity-info .user {
  font-weight: 500;
  margin-right: 4px;
}
.activity-info .time {
  font-size: 12px;
  color: #6b7280;
}

/* bottom row */
.bottom-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px;
}
.bottom-card {
  border-radius: 18px;
  background: #fff;
  min-height: 210px;
}

/* priority bars */
.priority-bars {
  margin-top: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.prio-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
.prio-label {
  width: 90px;
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
}
.prio-icon {
  width: 14px;
  height: 14px;
  border-radius: 9999px;
}
.prio-highest {
  background: #ef4444;
}
.prio-high {
  background: #f97316;
}
.prio-medium {
  background: #6b7280;
}
.prio-low {
  background: #60a5fa;
}
.prio-none {
  background: #d1d5db;
}
.prio-bar-wrap {
  background: #e5e7eb;
  border-radius: 9999px;
  height: 8px;
  flex: 1;
  overflow: hidden;
}
.prio-bar {
  background: #6b7280;
  height: 100%;
  border-radius: 9999px;
}
.prio-num {
  width: 24px;
  text-align: right;
  font-size: 12px;
}

/* types of work */
.types-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 12px;
}
.type-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
.type-name {
  width: 78px;
  display: flex;
  align-items: center;
  font-size: 12px;
}
.type-bar-wrap {
  flex: 1;
  background: #e5e7eb;
  border-radius: 9999px;
  height: 8px;
  overflow: hidden;
}
.type-bar {
  background: #9ca3af;
  height: 100%;
}
.type-perc {
  width: 36px;
  text-align: right;
  font-size: 12px;
}

/* team workload */
.team-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 12px;
}
.team-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
.team-name {
  width: 130px;
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
}
.team-bar-wrap {
  flex: 1;
  background: #e5e7eb;
  height: 7px;
  border-radius: 9999px;
  overflow: hidden;
}
.team-bar {
  background: #4b5563;
  height: 100%;
}
.team-perc {
  width: 40px;
  text-align: right;
  font-size: 12px;
}

/* epic empty */
.epic-card {
  display: flex;
  align-items: center;
  justify-content: center;
}
.empty-epic {
  text-align: center;
}
.empty-epic .icon-box {
  font-size: 34px;
}
.empty-epic .title {
  font-weight: 600;
  margin-top: 8px;
}
.empty-epic .sub {
  font-size: 12px;
  color: #6b7280;
  margin-top: 4px;
}

/* responsive */
@media (max-width: 1100px) {
  .main-row {
    grid-template-columns: 1fr;
  }
  .status-content {
    justify-content: flex-start;
  }
}
</style>
