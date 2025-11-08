<template>
  <div class="page">
    <!-- Header -->
    <h1 class="title">For you</h1>

    <!-- Recent spaces - CAROUSEL -->
    <div class="recent-section">
      <div class="section-header">
        <h2>Recent spaces</h2>
        <a class="link" href="#">View all spaces</a>
      </div>

      <div class="carousel-container" ref="carouselRef">
        <!-- Navigation Dots -->
        <div class="carousel-dots">
          <button 
            v-for="(dot, index) in visibleDots" 
            :key="index"
            class="dot"
            :class="{ active: index === currentDot }"
            @click="scrollToDot(index)"
          ></button>
        </div>

        <!-- Carousel Track -->
        <div 
          class="carousel-track" 
          ref="trackRef"
          @mousedown="onDragStart"
          @mouseleave="onDragEnd"
          @mouseup="onDragEnd"
          @mousemove="onDrag"
          @touchstart="onTouchStart"
          @touchmove="onTouchMove"
          @touchend="onTouchEnd"
        >
          <a-card
            v-for="space in spaces"
            :key="space.id"
            class="space-card"
            :style="{ borderLeft: `6px solid ${space.color}` }"
            :bodyStyle="{ display: 'flex', padding: '14px' }"
          >
            <div class="icon" v-html="space.iconSvg"></div>
            <div class="content">
              <div class="title">{{ space.title }}</div>
              <div class="subtitle">{{ space.subtitle }}</div>

              <div class="links">
                <div v-for="(v, k) in space.quickLinks" :key="k" class="link-row">
                  <span>{{ k }}</span>
                  <a-badge :count="v" v-if="v !== null" />
                </div>
              </div>

              <div class="footer">{{ space.footer }}</div>
            </div>
          </a-card>
        </div>

        <!-- Navigation Arrows -->
        <button class="carousel-arrow prev" @click="scrollPrev" :disabled="currentDot === 0">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M15 18L9 12L15 6"/>
          </svg>
        </button>
        <button class="carousel-arrow next" @click="scrollNext" :disabled="currentDot === visibleDots - 1">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 18L15 12L9 6"/>
          </svg>
        </button>
      </div>
    </div>

    <!-- Tabs -->
    <a-tabs v-model:activeKey="activeTab" class="tabs">
      <a-tab-pane key="worked" tab="Worked on" />
      <a-tab-pane key="viewed" tab="Viewed" />
      <a-tab-pane key="assigned" :tab="tabTitle('Assigned to me', 5)" />
    </a-tabs>

    <!-- Tasks -->
    <div class="task-list">
      <template v-for="group in groupedBySection" :key="group.section">
        <div class="section-header small">{{ group.section }}</div>
        <a-card
          v-for="task in group.items"
          :key="task.id"
          size="small"
          class="task-card"
          :bordered="false"
        >
          <div class="task-row">
            <div class="left">
              <span class="task-icon" v-html="task.typeIcon"></span>
              <div>
                <div class="task-title">{{ task.title }}</div>
                <div class="task-sub">{{ task.key }} · {{ task.space }}</div>
              </div>
            </div>
            <div class="status">{{ task.status }}</div>
          </div>
        </a-card>
      </template>

      <div v-if="filteredTasks.length === 0" class="empty">No items in this view.</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, h, onMounted, onUnmounted, nextTick } from 'vue'
import { Badge as ABadge, Card as ACard, Tabs as ATabs } from 'ant-design-vue'
import 'ant-design-vue/dist/reset.css'

// === MOCK DATA (GIỮ NGUYÊN 100%) ===
/**
 * --- MOCK DATA ---
 */
const spaces = [
  {
    id: 1,
    title: 'Support',
    subtitle: 'Service management',
    color: '#F7E7A4',
    iconSvg: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none">
      <rect x="3" y="3" width="18" height="18" rx="3" stroke="#7B6A2B" stroke-width="1" fill="#FFF6D6"/>
      <path d="M8 9h8M8 13h6" stroke="#7B6A2B" stroke-width="1.5" stroke-linecap="round"/>
    </svg>`,
    quickLinks: {
      'Recent queues': null,
      'All open': 2,
      'Assigned to me': 1
    },
    footer: '3 queues'
  },
  {
    id: 2,
    title: 'To Do List System',
    subtitle: 'Team-managed software',
    color: '#D6EEFF',
    iconSvg: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none">
      <rect x="3" y="3" width="18" height="18" rx="3" stroke="#2B6A9B" stroke-width="1" fill="#E9F6FF"/>
      <path d="M8 9h8M8 13h6" stroke="#2B6A9B" stroke-width="1.5" stroke-linecap="round"/>
    </svg>`,
    quickLinks: {
      'Quick links': null,
      'My open work items': 3,
      'Done work items': null
    },
    footer: '1 board'
  },
  {
    id: 3,
    title: 'Marketing Dashboard',
    subtitle: 'Performance tracking',
    color: '#FFD6D6',
    iconSvg: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="9" stroke="#B91C1C" stroke-width="1.5" fill="#FFECEC"/>
      <path d="M8 14h3V8h2v6h3" stroke="#B91C1C" stroke-width="1.5" stroke-linecap="round"/>
    </svg>`,
    quickLinks: { 'Recent reports': 1, 'Active campaigns': 2 },
    footer: '2 reports'
  },
  {
    id: 4,
    title: 'HR Portal',
    subtitle: 'Employee management',
    color: '#D6FFD6',
    iconSvg: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none">
      <rect x="3" y="3" width="18" height="18" rx="3" stroke="#166534" stroke-width="1.5" fill="#ECFDF5"/>
      <path d="M12 8a2 2 0 110 4 2 2 0 010-4Zm0 6c-2 0-4 1-4 3v1h8v-1c0-2-2-3-4-3Z" stroke="#166534" stroke-width="1.5"/>
    </svg>`,
    quickLinks: { 'Leave requests': 2, 'Approvals': 1 },
    footer: 'HR system'
  },
  {
    id: 5,
    title: 'Finance Hub',
    subtitle: 'Budget & invoices',
    color: '#E0D4F7',
    iconSvg: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none">
      <rect x="3" y="3" width="18" height="18" rx="3" stroke="#6B21A8" stroke-width="1.5" fill="#F5F3FF"/>
      <path d="M8 10h8M8 14h5" stroke="#6B21A8" stroke-width="1.5" stroke-linecap="round"/>
    </svg>`,
    quickLinks: { 'Pending invoices': 3, 'Reports': null },
    footer: 'Finance workspace'
  },
  {
    id: 6,
    title: 'Design Board',
    subtitle: 'Creative team tasks',
    color: '#FFF6E5',
    iconSvg: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none">
      <polygon points="4,20 20,20 12,4" stroke="#D97706" stroke-width="1.5" fill="#FEF3C7"/>
    </svg>`,
    quickLinks: { 'Active drafts': 2, 'Reviews': 1 },
    footer: '4 designs'
  },
  {
    id: 7,
    title: 'IT Operations',
    subtitle: 'Server and uptime logs',
    color: '#CCE5FF',
    iconSvg: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none">
      <rect x="3" y="4" width="18" height="6" rx="1.5" stroke="#1E40AF" stroke-width="1.5" fill="#E0F2FE"/>
      <rect x="3" y="14" width="18" height="6" rx="1.5" stroke="#1E40AF" stroke-width="1.5" fill="#E0F2FE"/>
    </svg>`,
    quickLinks: { 'Active alerts': 5, 'Resolved issues': null },
    footer: 'Monitoring tools'
  }
]

const activeTab = ref('assigned')

const tasks = ref([
  { id: 't1', title: 'Fix login redirect bug', key: 'TDL-1', space: 'To Do List System', status: 'In Progress', section: 'IN PROGRESS', typeIcon: `<svg width="24" height="24"><rect x="4" y="4" width="16" height="16" rx="2" fill="none" stroke="#2563EB" stroke-width="1.5"/></svg>` },
  { id: 't2', title: 'Create new marketing dashboard', key: 'MRK-3', space: 'Marketing Dashboard', status: 'To Do', section: 'TO DO', typeIcon: `<svg width="24" height="24"><path d="M5 5v14h14" fill="none" stroke="#10B981" stroke-width="1.5"/></svg>` },
  { id: 't3', title: 'Update HR leave flow', key: 'HR-12', space: 'HR Portal', status: 'In Progress', section: 'IN PROGRESS', typeIcon: `<svg width="24" height="24"><rect x="4" y="4" width="16" height="16" rx="2" fill="none" stroke="#16A34A" stroke-width="1.5"/></svg>` },
  { id: 't4', title: 'Add budget summary report', key: 'FIN-7', space: 'Finance Hub', status: 'Done', section: 'DONE', typeIcon: `<svg width="24" height="24"><path d="M6 12l4 4 8-8" stroke="#15803D" stroke-width="2" fill="none"/></svg>` },
  { id: 't5', title: 'Design new banner concept', key: 'DSN-5', space: 'Design Board', status: 'In Review', section: 'REVIEW', typeIcon: `<svg width="24" height="24"><circle cx="12" cy="12" r="8" stroke="#D97706" stroke-width="1.5" fill="none"/></svg>` },
  { id: 't6', title: 'Monitor uptime alerts', key: 'OPS-9', space: 'IT Operations', status: 'To Do', section: 'TO DO', typeIcon: `<svg width="24" height="24"><rect x="4" y="4" width="16" height="16" rx="2" fill="none" stroke="#1E40AF" stroke-width="1.5"/></svg>` },
  { id: 't7', title: 'Fix dashboard alignment', key: 'SUP-3', space: 'Support', status: 'In Progress', section: 'IN PROGRESS', typeIcon: `<svg width="24" height="24"><rect x="4" y="4" width="16" height="16" rx="2" fill="none" stroke="#7B6A2B" stroke-width="1.5"/></svg>` }
])

// === COMPUTED (GIỮ NGUYÊN) ===
const filteredTasks = computed(() => {
  switch (activeTab.value) {
    case 'assigned': return tasks.value
    case 'worked': return tasks.value.slice(0, 4)
    case 'viewed': return tasks.value.slice(2, 5)
    default: return []
  }
})

const groupedBySection = computed(() => {
  const bySection = {}
  for (const t of filteredTasks.value) {
    if (!bySection[t.section]) bySection[t.section] = []
    bySection[t.section].push(t)
  }
  return Object.keys(bySection).map(sec => ({ section: sec, items: bySection[sec] }))
})

const tabTitle = (label, count) => {
  return h('span', {}, [
    label,
    count ? h(ABadge, { count, style: { marginLeft: '6px', backgroundColor: '#EEF2FF', color: '#3730a3' } }) : null
  ])
}

// === CAROUSEL REFS ===
const carouselRef = ref(null)
const trackRef = ref(null)
const currentDot = ref(0)
const isDragging = ref(false)
const startX = ref(0)
const scrollLeft = ref(0)

// === CAROUSEL COMPUTED ===
const cardWidth = computed(() => {
  if (!trackRef.value || !carouselRef.value) return 300
  return 280 + 16 // card width + gap
})

const visibleCards = computed(() => {
  if (!carouselRef.value) return 1
  return Math.floor(carouselRef.value.clientWidth / cardWidth.value)
})

const totalDots = computed(() => {
  const cards = spaces.length
  const visible = visibleCards.value
  return Math.ceil(cards / visible)
})

const visibleDots = computed(() => totalDots.value)

// === CAROUSEL METHODS ===
const scrollToPosition = (position) => {
  if (trackRef.value) {
    trackRef.value.scrollTo({
      left: position,
      behavior: 'smooth'
    })
  }
}

const updateCurrentDot = () => {
  if (!trackRef.value || !carouselRef.value) return
  
  const scrollLeft = trackRef.value.scrollLeft
  const cardW = cardWidth.value
  const visible = visibleCards.value
  
  const newDot = Math.round(scrollLeft / (cardW * visible))
  currentDot.value = Math.max(0, Math.min(newDot, totalDots.value - 1))
}

const scrollPrev = () => {
  if (currentDot.value > 0) {
    const targetDot = currentDot.value - 1
    scrollToDot(targetDot)
  }
}

const scrollNext = () => {
  if (currentDot.value < totalDots.value - 1) {
    const targetDot = currentDot.value + 1
    scrollToDot(targetDot)
  }
}

const scrollToDot = (dotIndex) => {
  const cardW = cardWidth.value
  const visible = visibleCards.value
  const position = dotIndex * cardW * visible
  scrollToPosition(position)
}

// === DRAG & TOUCH ===
const onDragStart = (e) => {
  isDragging.value = true
  startX.value = e.pageX - trackRef.value.offsetLeft
  scrollLeft.value = trackRef.value.scrollLeft
  trackRef.value.style.cursor = 'grabbing'
}

const onDrag = (e) => {
  if (!isDragging.value) return
  e.preventDefault()
  const x = e.pageX - trackRef.value.offsetLeft
  const walk = (x - startX.value) * 2
  trackRef.value.scrollLeft = scrollLeft.value - walk
}

const onDragEnd = () => {
  isDragging.value = false
  trackRef.value.style.cursor = 'grab'
  updateCurrentDot()
}

const onTouchStart = (e) => {
  isDragging.value = true
  startX.value = e.touches[0].pageX
  scrollLeft.value = trackRef.value.scrollLeft
}

const onTouchMove = (e) => {
  if (!isDragging.value) return
  const x = e.touches[0].pageX
  const walk = (x - startX.value) * 2
  trackRef.value.scrollLeft = scrollLeft.value - walk
}

const onTouchEnd = () => {
  isDragging.value = false
  updateCurrentDot()
}

// === LIFECYCLE ===
onMounted(async () => {
  await nextTick()
  if (trackRef.value) {
    trackRef.value.addEventListener('scroll', updateCurrentDot)
    updateCurrentDot()
  }
})

onUnmounted(() => {
  if (trackRef.value) {
    trackRef.value.removeEventListener('scroll', updateCurrentDot)
  }
})
</script>

<style scoped>
.page {
  max-height: 690px;
  overflow-y: auto;
  padding: 24px;
  font-family: Inter, sans-serif;
  background: #fff;
  color: #222;
}

.title {
  font-size: 28px;
  font-weight: 700;
  margin-bottom: 20px;
}

/* ======= Recent spaces ======= */
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}
.section-header h2 {
  font-size: 16px;
  font-weight: 600;
}
.section-header.small {
  font-size: 12px;
  color: #6b7280;
  text-transform: uppercase;
  font-weight: 700;
  margin-top: 16px;
  margin-bottom: 6px;
}
.link {
  font-size: 14px;
  color: #1677ff;
  text-decoration: none;
}
.cards {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}
.space-card {
  width: 280px;
  border-radius: 6px;
}
.icon {
  width: 44px;
  margin-right: 10px;
}
.content {
  flex: 1;
}
.content .title {
  font-weight: 600;
}
.subtitle {
  color: #6b7280;
  font-size: 13px;
  margin-bottom: 8px;
}
.link-row {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  margin: 2px 0;
}
.footer {
  font-size: 13px;
  color: #6b7280;
  margin-top: 6px;
}

/* ===== Tabs ===== */
.tabs {
  margin-top: 20px;
}

/* ===== Tasks ===== */
.task-card {
  border-bottom: 1px solid #f0f0f0;
  border-radius: 0;
}
.task-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.left {
  display: flex;
  align-items: center;
  gap: 10px;
}
.task-title {
  font-weight: 600;
}
.task-sub {
  font-size: 13px;
  color: #6b7280;
}
.status {
  font-size: 14px;
  color: #6b7280;
}
.empty {
  text-align: center;
  padding: 20px;
  color: #6b7280;
}
</style>