<template>
  <div class="page">
    <!-- Header -->
    <div class="hero">
      <div class="hero-left">
        <h1 class="title">For you</h1>
        <p class="subtitle">Tổng quan nhanh những gì bạn quan tâm gần đây.</p>
      </div>
      <div class="hero-actions">
        <a-button type="primary" @click="loadRecent" :loading="loadingAll">Refresh</a-button>
      </div>
    </div>

    <!-- Recent spaces -->
    <div class="block">
      <div class="block-header">
        <div class="block-title">
          <span class="dot"></span>
          <h2>Recent spaces</h2>
        </div>
        <a-button type="link" @click="loadRecentSpaces" :loading="loading.spaces">Reload</a-button>
      </div>

      <div class="carousel-wrapper glass">
        <button class="nav-btn left" @click="scrollLeftBtn">‹</button>

        <div
          class="cards carousel"
          ref="carouselRef"
          @mousedown="startDrag"
          @mousemove="onDrag"
          @mouseup="stopDrag"
          @mouseleave="stopDrag"
        >
          <!-- Skeleton khi loading -->
          <template v-if="loading.spaces">
            <div v-for="i in 4" :key="'sk-'+i" class="space-card skeleton-card"></div>
          </template>

          <!-- Items -->
          <a-card
            v-else
            v-for="s in spaces"
            :key="s.uuid"
            class="space-card hover-rise"
            :bodyStyle="{ display: 'flex', padding: '14px', height: '100%' }"
          >
            <div class="content">
              <div class="space-top">
                <div class="space-avatar">
                  <span>{{ (s.name || '').slice(0,1).toUpperCase() }}</span>
                </div>
                <div class="space-top-right">
                  <div class="space-name" :title="s.name">{{ s.name }}</div>
                  <div class="chips">
                    <span class="chip" v-if="s.type_name">{{ s.type_name }}</span>
                    <span class="chip" v-if="s.status">{{ s.status }}</span>
                  </div>
                </div>
              </div>

              <div class="meta">
                <div class="meta-row">
                  <span class="meta-key">Key</span>
                  <span class="meta-val">{{ s.key || '—' }}</span>
                </div>
                <div class="meta-row">
                  <span class="meta-key">URL</span>
                  <a
                    v-if="s.url"
                    :href="s.url"
                    target="_blank"
                    rel="noopener"
                    class="meta-val link"
                  >{{ s.url }}</a>
                  <span v-else class="meta-val">—</span>
                </div>
                <div class="meta-row">
                  <span class="meta-key">Lead</span>
                  <span class="meta-val">{{ s.lead_username || s.lead_email || '—' }}</span>
                </div>
              </div>

              <div class="footer">
                <span>Created: {{ fmtDate(s.created_date) }}</span>
                <span>Updated: {{ fmtDate(s.updated_date) }}</span>
              </div>
            </div>
          </a-card>

          <a-empty v-if="!spaces.length && !loading.spaces" description="No spaces" />
        </div>

        <button class="nav-btn right" @click="scrollRightBtn">›</button>
      </div>
    </div>

    <!-- Recent tasks -->
    <div class="block">
      <div class="block-header">
        <div class="block-title">
          <span class="dot"></span>
          <h2>Recent tasks</h2>
        </div>
        <a-button type="link" @click="loadRecentTasks" :loading="loading.tasks">Reload</a-button>
      </div>

      <div class="task-list">
        <!-- Skeleton khi loading -->
        <template v-if="loading.tasks">
          <a-card v-for="i in 4" :key="'tsk-sk-'+i" size="small" class="task-card skeleton-line" />
        </template>

        <!-- Items -->
        <a-card
          v-else
          v-for="t in tasks"
          :key="t.uuid"
          size="small"
          class="task-card hover-outline"
          :bordered="false"
        >
          <div class="task-row">
            <div class="left">
              <div class="task-icon">
                <svg width="22" height="22" viewBox="0 0 24 24">
                  <rect x="4" y="4" width="16" height="16" rx="4" fill="currentColor" opacity="0.1"/>
                  <path d="M8 12h8M8 16h5M8 8h8" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
                </svg>
              </div>

              <div class="task-main">
                <div class="task-title" :title="t.title">{{ t.title }}</div>

                <div class="task-sub">
                  <span class="pill" v-if="t.key">{{ t.key }}</span>
                  <span class="pill neutral" v-if="t.status">Status: {{ t.status }}</span>
                  <span class="pill warn" v-if="t.priority">Priority: {{ t.priority }}</span>
                </div>

                <div class="task-sub dim">
                  <span>Space: <strong>{{ t.space_name || t.space_id || '—' }}</strong></span>
                  <span>· Assignee: <strong>{{ t.assignee_username || t.assignee || '—' }}</strong></span>
                  <span>· Owner: <strong>{{ t.owner_username || t.owner || '—' }}</strong></span>
                </div>

                <div class="task-sub dim">
                  <span>Due: {{ fmtDate(t.due_date) }}</span>
                  <span>· Updated: {{ fmtDate(t.updated_date) }}</span>
                </div>
              </div>
            </div>
          </div>
        </a-card>

        <div v-if="!tasks.length && !loading.tasks" class="empty">No tasks</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { Button as AButton, Card as ACard, Empty as AEmpty, message } from 'ant-design-vue'
import 'ant-design-vue/dist/reset.css'
import axiosClient from '@/utils/axiosClient'

/* ======= STATE ======= */
const loading = reactive({ spaces: false, tasks: false })
const loadingAll = computed(() => loading.spaces || loading.tasks)
const spaces = ref([])
const tasks = ref([])

/* ======= LOAD RECENT ======= */
async function loadRecentSpaces () {
  loading.spaces = true
  try {
    // 10 space gần đây theo created_date desc
    const res = await axiosClient.get('', {
      params: {
        c: 'Space',
        m: 'index',
        sort_by: 'created_date',
        sort_dir: 'desc',
        page: 1,
        per_page: 10
      }
    })
    const data = res?.data
    spaces.value = data?.data || []
  } catch (e) {
    message.error('Tải spaces thất bại')
    console.error(e)
  } finally {
    loading.spaces = false
  }
}

async function loadRecentTasks () {
  loading.tasks = true
  try {
    // Dùng dạng c=Task&m=index như yêu cầu
    const res = await axiosClient.get('', {
      params: {
        c: 'Task',
        m: 'index',
        sort: '-created_date',
        page: 1,
        per_page: 10
      }
    })
    const data = res?.data
    tasks.value = data?.data || []
  } catch (e) {
    message.error('Tải tasks thất bại')
    console.error(e)
  } finally {
    loading.tasks = false
  }
}

async function loadRecent () {
  await Promise.all([loadRecentSpaces(), loadRecentTasks()])
}

/* ======= SMALL UTILS ======= */
function fmtDate (s) {
  if (!s) return '—'
  try {
    const d = new Date(s)
    if (isNaN(d.getTime())) return '—'
    return d.toISOString().slice(0, 10)
  } catch {
    return '—'
  }
}

/* ======= CAROUSEL (UI) ======= */
const carouselRef = ref(null)
let isDragging = false
let startX, scrollStart

const startDrag = (e) => {
  isDragging = true
  startX = e.pageX - carouselRef.value.offsetLeft
  scrollStart = carouselRef.value.scrollLeft
  carouselRef.value.classList.add('dragging')
}
const stopDrag = () => {
  isDragging = false
  carouselRef.value?.classList.remove('dragging')
}
const onDrag = (e) => {
  if (!isDragging) return
  e.preventDefault()
  const x = e.pageX - carouselRef.value.offsetLeft
  const walk = (x - startX) * 1.2
  carouselRef.value.scrollLeft = scrollStart - walk
}
const scrollLeftBtn = () => {
  carouselRef.value.scrollBy({ left: -300, behavior: 'smooth' })
}
const scrollRightBtn = () => {
  carouselRef.value.scrollBy({ left: 300, behavior: 'smooth' })
}

/* ======= LIFECYCLE ======= */
onMounted(loadRecent)
</script>

<style scoped>
/* ===== Page ===== */
.page {
  max-height: 690px;
  overflow-y: auto;
  padding: 24px;
  font-family: Inter, system-ui, -apple-system, sans-serif;
  background: linear-gradient(180deg, #fafbff 0%, #ffffff 60%);
  color: #1f2937;
}

/* ===== Hero ===== */
.hero {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 16px;
  margin-bottom: 20px;
}
.title {
  font-size: 28px;
  font-weight: 800;
  letter-spacing: -0.02em;
  margin: 0 0 6px;
}
.subtitle {
  color: #6b7280;
  margin: 0;
}

/* ===== Block ===== */
.block {
  margin-top: 10px;
}
.block-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin: 6px 0 10px;
}
.block-title {
  display: flex;
  align-items: center;
  gap: 8px;
}
.block-title h2 {
  font-size: 16px;
  font-weight: 700;
  margin: 0;
}
.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #6366f1;
  box-shadow: 0 0 0 4px rgba(99,102,241,0.12);
}

/* ===== Glass panel ===== */
.glass {
  border-radius: 14px;
  background: rgba(255,255,255,0.7);
  backdrop-filter: blur(6px);
  border: 1px solid #eef2ff;
  box-shadow: 0 6px 24px rgba(99,102,241,0.08);
}

/* ===== Carousel ===== */
.carousel-wrapper {
  position: relative;
  overflow: hidden;
  padding: 8px;
}
.carousel {
  display: flex;
  gap: 16px;
  overflow-x: auto;
  scroll-behavior: smooth;
  padding: 6px 10px;
}
.carousel::-webkit-scrollbar { height: 6px; }
.carousel::-webkit-scrollbar-thumb { background: #e5e7eb; border-radius: 3px; }
.carousel.dragging { cursor: grabbing; scroll-behavior: auto; }

.space-card {
  min-width: 280px;
  max-width: 280px;
  height: 240px;
  flex: 0 0 auto;
  border-radius: 12px;
  border: 1px solid #eef2ff;
}
.hover-rise {
  transition: transform .18s ease, box-shadow .18s ease;
}
.hover-rise:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 24px rgba(17,24,39,0.08);
}
.skeleton-card {
  background: linear-gradient(90deg,#f3f4f6 25%,#eef2ff 37%,#f3f4f6 63%);
  background-size: 400% 100%;
  animation: shimmer 1.4s ease-in-out infinite;
  border-radius: 12px;
}
@keyframes shimmer { 0%{background-position: 200% 0} 100%{background-position: -200% 0} }

.content { display: flex; flex-direction: column; justify-content: space-between; width: 100%; }
.space-top { display: flex; align-items: center; gap: 12px; }
.space-avatar {
  width: 44px; height: 44px; border-radius: 10px;
  background: #eef2ff; color: #4f46e5;
  display: inline-flex; align-items: center; justify-content: center;
  font-weight: 800; letter-spacing: -0.02em;
}
.space-name { font-weight: 800; font-size: 16px; letter-spacing: -0.01em; }
.chips { margin-top: 4px; display: flex; gap: 6px; flex-wrap: wrap; }
.chip {
  display: inline-block; font-size: 12px; line-height: 18px; padding: 0 8px;
  background: #f3f4f6; border: 1px solid #e5e7eb; border-radius: 999px; color: #374151;
}

.meta { margin-top: 10px; }
.meta-row { display: flex; justify-content: space-between; font-size: 13px; margin: 3px 0; gap: 8px; }
.meta-key { color: #6b7280; min-width: 56px; }
.meta-val { text-align: right; max-width: 180px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.footer { display: flex; justify-content: space-between; font-size: 12px; color: #6b7280; margin-top: 8px; }

/* ===== Nav buttons ===== */
.nav-btn {
  position: absolute; top: 50%; transform: translateY(-50%);
  background: white; border: 1px solid #e5e7eb; border-radius: 50%;
  width: 34px; height: 34px; font-size: 18px; color: #444;
  cursor: pointer; transition: all 0.2s; z-index: 2;
}
.nav-btn:hover { background: #4f46e5; color: white; border-color: #4f46e5; }
.nav-btn.left { left: 2px; }
.nav-btn.right { right: 2px; }

/* ===== Tasks ===== */
.task-card {
  border-bottom: 1px solid #f3f4f6;
  border-radius: 12px;
  margin-top: 10px;
  background: white;
}
.hover-outline { transition: box-shadow .18s ease, border-color .18s ease; }
.hover-outline:hover { box-shadow: 0 10px 24px rgba(17,24,39,0.06); border-color: #e5e7eb; }

.task-row { display: flex; justify-content: space-between; align-items: flex-start; }
.left { display: flex; align-items: flex-start; gap: 12px; }
.task-icon { color: #4f46e5; margin-top: 2px; }
.task-title { font-weight: 700; letter-spacing: -0.01em; }
.task-sub { font-size: 13px; color: #374151; display: flex; gap: 8px; flex-wrap: wrap; margin-top: 6px; }
.task-sub.dim { color: #6b7280; }
.pill {
  font-size: 12px; line-height: 18px; padding: 0 8px; border-radius: 999px;
  border: 1px solid #e5e7eb; background: #f9fafb; color: #374151;
}
.pill.neutral { background: #f3f4f6; }
.pill.warn { background: #fff7ed; border-color: #fed7aa; }

.skeleton-line {
  height: 72px;
  background: linear-gradient(90deg,#f3f4f6 25%,#eef2ff 37%,#f3f4f6 63%);
  background-size: 400% 100%;
  animation: shimmer 1.4s ease-in-out infinite;
  border-radius: 12px;
}

.empty { text-align: center; padding: 24px; color: #9ca3af; }
.link { color: #4f46e5; text-decoration: none; }
</style>
