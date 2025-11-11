<template>
  <div class="page">
    <!-- Hero -->
    <div class="hero">
      <div class="hero-left">
        <h1 class="title">Spaces</h1>
        <p class="subtitle">Quản lý & theo dõi không gian làm việc của bạn.</p>
      </div>
      <div class="hero-actions">
        <a-button type="primary" @click="openCreate">Create space</a-button>
      </div>
    </div>

    <!-- Toolbar (glass) -->
    <div class="toolbar glass">
      <a-input
        v-model:value="state.q"
        allow-clear
        placeholder="Search spaces (name, key, url)"
        class="toolbar-input"
        @change="goFirstPageAndLoad"
        @pressEnter="goFirstPageAndLoad"
      >
        <template #prefix>
          <svg width="16" height="16" viewBox="0 0 24 24">
            <path d="M11 4a7 7 0 015.292 11.708l3 3a1 1 0 11-1.414 1.414l-3-3A7 7 0 1111 4zm0 2a5 5 0 100 10 5 5 0 000-10z" fill="currentColor"/>
          </svg>
        </template>
      </a-input>

      <a-select
        v-model:value="state.filters.type_id"
        :options="typeOptions"
        allow-clear
        placeholder="Filter by type"
        class="toolbar-select"
        @change="goFirstPageAndLoad"
      />

      <a-select
        v-model:value="state.filters.lead_id"
        :options="leadOptions"
        show-search
        allow-clear
        placeholder="Lead"
        class="toolbar-select wide"
        option-filter-prop="label"
        @change="goFirstPageAndLoad"
      />

      <a-select
        v-model:value="state.filters.status"
        :options="statusOptions"
        allow-clear
        placeholder="Status"
        class="toolbar-select"
        @change="goFirstPageAndLoad"
      />

      <a-divider type="vertical" class="divider" />

      <a-dropdown trigger="click">
        <a-button>Columns</a-button>
        <template #overlay>
          <div class="dropdown-pane">
            <div v-for="c in allColumnKeys" :key="c" class="row">
              <a-checkbox :checked="visibleColsSet.has(c)" @change="toggleColumn(c)">
                {{ columnLabels[c] || c }}
              </a-checkbox>
            </div>
          </div>
        </template>
      </a-dropdown>

      <div class="spacer"></div>

      <template v-if="selectedRowKeys.length">
        <a-popconfirm
          title="Delete selected?"
          ok-text="Delete"
          cancel-text="Cancel"
          @confirm="bulkDelete"
        >
          <a-button danger>Delete ({{ selectedRowKeys.length }})</a-button>
        </a-popconfirm>
      </template>
    </div>

    <!-- Table block -->
    <div class="table-wrap glass">
      <!-- Skeleton loading overlay -->
      <transition name="fade">
        <div v-if="loading.table" class="skeleton-overlay">
          <div class="skeleton-header"></div>
          <div class="skeleton-row" v-for="i in 8" :key="'sk-'+i"></div>
        </div>
      </transition>

      <a-table
        :data-source="rows"
        :columns="tableColumns"
        :row-key="row => row.uuid"
        :pagination="false"
        :size="density"
        :row-selection="rowSelection"
        class="spaces-table"
        bordered
      >
        <template #bodyCell="{ column, record, text }">
          <!-- Name (clickable if URL) -->
          <template v-if="column.key === 'name'">
            <div class="cell-name hover-rise-inline">
              <div class="avatar">{{ (record.name || '').slice(0,1).toUpperCase() }}</div>
              <div class="name-meta">
                <a
                  v-if="record.url"
                  class="link-like"
                  :href="record.url"
                  target="_blank"
                  rel="noopener noreferrer"
                  @click.stop
                >{{ record.name }}</a>
                <span v-else class="strong">{{ record.name }}</span>
                <div class="chips">
                  <span class="chip" v-if="record.type_name">{{ record.type_name }}</span>
                  <span class="chip neutral" v-if="record.status">{{ record.status }}</span>
                </div>
              </div>
            </div>
          </template>

          <!-- Key -->
          <template v-else-if="column.key === 'key'">
            <code class="mono badge">{{ record.key }}</code>
          </template>

          <!-- Type -->
          <template v-else-if="column.key === 'type_name'">
            <a-tag>{{ record.type_name || '—' }}</a-tag>
          </template>

          <!-- Lead -->
          <template v-else-if="column.key === 'lead'">
            <div class="lead">
              <a-avatar size="small">{{ initialsFrom(record.lead_username || record.lead_email) }}</a-avatar>
              <span class="lead-name">
                <a-tooltip :title="record.lead_email">{{ record.lead_username || '—' }}</a-tooltip>
              </span>
            </div>
          </template>

          <!-- Status -->
          <template v-else-if="column.key === 'status'">
            <a-tag :color="statusColor(record.status)">{{ record.status || '—' }}</a-tag>
          </template>

          <!-- Updated -->
          <template v-else-if="column.key === 'updated_date'">
            <span class="muted">{{ formatDate(record.updated_date) }}</span>
          </template>

          <!-- Actions -->
          <template v-else-if="column.key === 'actions'">
            <a-dropdown :trigger="['click']">
              <a-button size="small">⋯</a-button>
              <template #overlay>
                <a-menu>
                  <a-menu-item @click="record.url ? openUrl(record.url) : null" :disabled="!record.url">Open</a-menu-item>
                  <a-menu-item @click="copy(record.url)" :disabled="!record.url">Copy URL</a-menu-item>
                  <a-menu-divider />
                  <a-menu-item @click="openEdit(record)">Edit</a-menu-item>
                  <a-menu-item danger @click="deleteOne(record)">Delete</a-menu-item>
                </a-menu>
              </template>
            </a-dropdown>
          </template>

          <template v-else>
            {{ text }}
          </template>
        </template>
      </a-table>

      <div v-if="!loading.table && !rows.length" class="empty-state">
        <a-empty description="No spaces found" />
      </div>
    </div>

    <!-- Pagination -->
    <div class="pagination">
      <a-pagination
        :current="pagination.current_page"
        :page-size="pagination.per_page"
        :total="pagination.total"
        show-size-changer
        :page-size-options="['5','10','20','50','100']"
        @change="(p, ps) => { pagination.current_page = p; pagination.per_page = ps; loadSpaces() }"
        @showSizeChange="(p, ps) => { pagination.current_page = 1; pagination.per_page = ps; loadSpaces() }"
      />
    </div>

    <!-- ===== Create Space Modal ===== -->
    <a-modal
      v-model:open="createOpen"
      title="Create space"
      :confirm-loading="createLoading"
      @ok="submitCreate"
      @cancel="closeCreate"
      :width="560"
      destroyOnClose
    >
      <a-form layout="vertical">
        <a-form-item label="Name" :required="true">
          <a-input v-model:value="createForm.name" placeholder="e.g. Support" />
        </a-form-item>

        <div class="row-2">
          <a-form-item label="Key" :required="true">
            <a-input v-model:value="createForm.key" placeholder="e.g. SUP" />
          </a-form-item>
          <a-form-item label="Type">
            <a-select
              v-model:value="createForm.type_id"
              :options="typeOptions"
              placeholder="Select type"
              allow-clear
            />
          </a-form-item>
        </div>

        <a-form-item label="Lead">
          <a-select
            v-model:value="createForm.lead_id"
            :options="leadOptions"
            show-search
            allow-clear
            placeholder="Person in charge"
            option-filter-prop="label"
          />
        </a-form-item>

        <div class="row-2">
          <a-form-item label="Status">
            <a-select
              v-model:value="createForm.status"
              :options="statusOptions"
              allow-clear
              placeholder="Status"
            />
          </a-form-item>
          <a-form-item label="URL">
            <a-input v-model:value="createForm.url" placeholder="https://example.com/space" />
          </a-form-item>
        </div>

        <a-alert type="info" show-icon message="Tip"
                 description="Key sẽ tự gợi ý từ Name (có thể sửa)."
                 style="margin-top: 6px;" />
      </a-form>
    </a-modal>

    <!-- ===== Edit Space Modal ===== -->
    <a-modal
      v-model:open="editOpen"
      title="Edit space"
      :confirm-loading="editLoading"
      @ok="submitEdit"
      @cancel="closeEdit"
      :width="560"
      destroyOnClose
    >
      <a-form layout="vertical">
        <a-form-item label="Name" :required="true">
          <a-input v-model:value="editForm.name" />
        </a-form-item>

        <div class="row-2">
          <a-form-item label="Key" :required="true">
            <a-input v-model:value="editForm.key" />
          </a-form-item>
          <a-form-item label="Type">
            <a-select
              v-model:value="editForm.type_id"
              :options="typeOptions"
              allow-clear
            />
          </a-form-item>
        </div>

        <a-form-item label="Lead">
          <a-select
            v-model:value="editForm.lead_id"
            :options="leadOptions"
            show-search
            allow-clear
            option-filter-prop="label"
          />
        </a-form-item>

        <div class="row-2">
          <a-form-item label="Status">
            <a-select
              v-model:value="editForm.status"
              :options="statusOptions"
              allow-clear
            />
          </a-form-item>
          <a-form-item label="URL">
            <a-input v-model:value="editForm.url" />
          </a-form-item>
        </div>

        <a-alert type="info" show-icon message="Note"
                 description="Chỉ các trường của API được hiển thị/cập nhật."
                 style="margin-top: 6px;" />
      </a-form>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, reactive, computed, h, onMounted, watch } from 'vue'
import {
  Input as AInput,
  Select as ASelect,
  Button as AButton,
  Table as ATable,
  Tag as ATag,
  Avatar as AAvatar,
  Dropdown as ADropdown,
  Menu as AMenu,
  Divider as ADivider,
  Checkbox as ACheckbox,
  Pagination as APagination,
  Tooltip as ATooltip,
  Popconfirm as APopconfirm,
  Modal as AModal,
  Form as AForm,
  Alert as AAlert,
  Empty as AEmpty,
  message
} from 'ant-design-vue'
import 'ant-design-vue/dist/reset.css'
import axiosClient from '@/utils/axiosClient'

/* -------------------- STATE -------------------- */
const state = reactive({
  q: '',
  filters: {
    type_id: null,
    lead_id: null,
    status: null
  },
  sort_by: 'created_date',
  sort_dir: 'desc'
})

const density = ref('middle')

const rows = ref([])
const loading = reactive({
  table: false
})
const pagination = reactive({
  current_page: 1,
  per_page: 10,
  total: 0
})

/* options cho filter/select */
const typeOptions = ref([])
const leadOptions = ref([])
const statusOptions = ref([])

/* selection */
const selectedRowKeys = ref([])
const rowSelection = computed(() => ({
  selectedRowKeys: selectedRowKeys.value,
  onChange: (keys) => { selectedRowKeys.value = keys }
}))

/* -------------------- COLUMNS -------------------- */
const columnLabels = {
  name: 'Name',
  key: 'Key',
  type_name: 'Type',
  lead: 'Lead',
  status: 'Status',
  updated_date: 'Updated',
  actions: ''
}
const allColumnKeys = ['name','key','type_name','lead','status','updated_date','actions']
const visibleColsSet = ref(new Set(allColumnKeys))

const toggleColumn = (key) => {
  const set = new Set(visibleColsSet.value)
  if (set.has(key)) set.delete(key); else set.add(key)
  // đảm bảo tối thiểu vẫn còn các cột chính
  if (![...set].some(k => ['name','key','status'].includes(k))) return
  visibleColsSet.value = set
}

const tableColumns = computed(() => {
  const cols = []
  if (visibleColsSet.value.has('name')) cols.push(sortableHeader('Name', 'name', 320))
  if (visibleColsSet.value.has('key'))  cols.push(sortableHeader('Key', 'key', 120))
  if (visibleColsSet.value.has('type_name')) cols.push({ title: 'Type', dataIndex: 'type_name', key: 'type_name', width: 160 })
  if (visibleColsSet.value.has('lead')) cols.push({ title: 'Lead', dataIndex: 'lead', key: 'lead', width: 220 })
  if (visibleColsSet.value.has('status')) cols.push(sortableHeader('Status', 'status', 140))
  if (visibleColsSet.value.has('updated_date')) cols.push(sortableHeader('Updated', 'updated_date', 170))
  if (visibleColsSet.value.has('actions')) cols.push({ title: '', key: 'actions', align: 'right', width: 90 })
  return cols
})

function sortableHeader(titleText, key, width) {
  const active = state.sort_by === key
  const icon = active ? (state.sort_dir === 'asc' ? '↑' : '↓') : '↕'
  const sortableWhitelist = ['name','key','status','created_date','updated_date']
  const isAllowed = sortableWhitelist.includes(key)
  return {
    title: () => h('span', {
      class: isAllowed ? 'sortable' : '',
      onClick: isAllowed ? () => toggleSort(key) : null
    }, [titleText, ' ', h('span', { class: 'sort-icon' }, icon)]),
    dataIndex: key,
    key,
    width
  }
}
function toggleSort(by) {
  if (state.sort_by === by) {
    state.sort_dir = (state.sort_dir === 'asc') ? 'desc' : 'asc'
  } else {
    state.sort_by = by
    state.sort_dir = 'asc'
  }
  goFirstPageAndLoad()
}

/* -------------------- LOADERS -------------------- */
async function loadSpaces() {
  try {
    loading.table = true
    const res = await axiosClient.get('', {
      params: {
        c: 'Space',
        m: 'index',
        q: state.q || undefined,
        type_id: state.filters.type_id || undefined,
        lead_id: state.filters.lead_id || undefined,
        status: state.filters.status || undefined,
        sort_by: state.sort_by,
        sort_dir: state.sort_dir,
        page: pagination.current_page,
        per_page: pagination.per_page
      }
    })
    const data = res.data || {}
    rows.value = Array.isArray(data.data) ? data.data : []
    pagination.current_page = data.current_page || 1
    pagination.per_page = data.per_page || 10
    pagination.total = data.total || rows.value.length
    // chuẩn hóa nhanh cho cột lead
    rows.value = rows.value.map(r => ({
      ...r,
      lead: r.lead_username || r.lead_email || '—'
    }))
  } catch (err) {
    message.error(apiError(err, 'Failed to load spaces'))
  } finally {
    // tạo độ “trễ” nhỏ để skeleton mượt hơn
    setTimeout(() => { loading.table = false }, 200)
  }
}

async function loadTypeOptions() {
  try {
    const res = await axiosClient.get('', { params: { c: 'Space', m: 'types' } })
    typeOptions.value = (res.data?.data || []).map(o => ({ label: o.label, value: o.value }))
  } catch {
    typeOptions.value = []
  }
}
async function loadLeadOptions() {
  try {
    const res = await axiosClient.get('', { params: { c: 'Space', m: 'leads' } })
    leadOptions.value = (res.data?.data || []).map(o => ({ label: o.label, value: o.value }))
  } catch {
    leadOptions.value = []
  }
}
async function loadStatusOptions() {
  try {
    const res = await axiosClient.get('', { params: { c: 'Space', m: 'statuses' } })
    statusOptions.value = (res.data?.data || []).map(o => ({ label: o.label, value: o.value }))
  } catch {
    statusOptions.value = []
  }
}

function goFirstPageAndLoad() {
  pagination.current_page = 1
  loadSpaces()
}

/* -------------------- ACTIONS -------------------- */
function openUrl(url) {
  window.open(url, '_blank')
}
function copy(text) {
  if (!text) return
  navigator.clipboard.writeText(text)
  message.success('Copied')
}
function formatDate(d) {
  if (!d) return '—'
  try { return new Date(d).toLocaleString() } catch { return d }
}
function statusColor(s) {
  if (!s) return 'default'
  const v = String(s).toLowerCase()
  if (['active','open','enabled'].includes(v)) return 'green'
  if (['archived','disabled','closed'].includes(v)) return 'default'
  if (['pending','draft'].includes(v)) return 'gold'
  return 'blue'
}
function initialsFrom(s) {
  if (!s) return ''
  const parts = String(s).trim().split(/\s+/)
  if (parts.length === 1) return parts[0].slice(0,2).toUpperCase()
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
}
function keyFromName(name) {
  if (!name) return ''
  const words = name.replace(/[^\p{L}\p{N}\s]/gu,' ').split(/\s+/).filter(Boolean)
  let key = words.length > 1 ? words.map(w => w[0]).join('') : words[0].slice(0,3)
  return key.toUpperCase().slice(0,10)
}

/* delete one & bulk delete */
async function deleteOne(rec) {
  try {
    await axiosClient.delete('', { params: { c: 'Space', m: 'destroy', uuid: rec.uuid } })
    message.success('Deleted')
    loadSpaces()
  } catch (err) {
    message.error(apiError(err, 'Delete failed'))
  }
}
async function bulkDelete() {
  const ids = selectedRowKeys.value
  if (!ids.length) return
  try {
    await Promise.all(ids.map(uuid =>
      axiosClient.delete('', { params: { c: 'Space', m: 'destroy', uuid } })
    ))
    selectedRowKeys.value = []
    message.success('Deleted selected')
    loadSpaces()
  } catch (err) {
    message.error(apiError(err, 'Bulk delete failed'))
  }
}

/* export (nếu cần bật) */
function exportCSV() {
  const header = ['UUID','Name','Key','Type','Lead Username','Lead Email','Status','URL','Created','Updated']
  const data = rows.value.map(r => [
    r.uuid, r.name, r.key, r.type_name || '', r.lead_username || '', r.lead_email || '',
    r.status || '', r.url || '', r.created_date || '', r.updated_date || ''
  ])
  const csv = [header, ...data].map(r => r.map(csvEscape).join(',')).join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = `spaces_${Date.now()}.csv`
  a.click()
  URL.revokeObjectURL(a.href)
}
const csvEscape = (v) => {
  const s = String(v ?? '')
  return /[",\n]/.test(s) ? `"${s.replace(/"/g,'""')}"` : s
}

/* -------------------- CREATE -------------------- */
const createOpen = ref(false)
const createLoading = ref(false)
const createForm = reactive({
  name: '',
  key: '',
  type_id: null,
  lead_id: null,
  status: null,
  url: ''
})
function openCreate() {
  Object.assign(createForm, { name: '', key: '', type_id: null, lead_id: null, status: null, url: '' })
  createOpen.value = true
}
function closeCreate() { createOpen.value = false }

watch(() => createForm.name, (val) => {
  // tự gợi ý key từ name (có thể sửa)
  const guess = keyFromName(val || '')
  if (!createForm.key || createForm.key === guess.slice(0, createForm.key.length)) {
    createForm.key = guess
  }
})

async function submitCreate() {
  if (!createForm.name.trim()) { message.error('Please enter Name'); return }
  if (!createForm.key.trim())  { message.error('Please enter Key'); return }

  createLoading.value = true
  try {
    await axiosClient.post('', {
      name: createForm.name.trim(),
      key: createForm.key.trim(),
      type_id: createForm.type_id || null,
      lead_id: createForm.lead_id || null,
      status: createForm.status || null,
      url: (createForm.url || '').trim() || null
    }, {
      params: { c: 'Space', m: 'store' }
    })
    message.success('Space created')
    createOpen.value = false
    goFirstPageAndLoad()
  } catch (err) {
    message.error(apiError(err, 'Create failed'))
  } finally {
    createLoading.value = false
  }
}

/* -------------------- EDIT -------------------- */
const editOpen = ref(false)
const editLoading = ref(false)
const editForm = reactive({
  uuid: '',
  name: '',
  key: '',
  type_id: null,
  lead_id: null,
  status: null,
  url: ''
})
function openEdit(rec) {
  Object.assign(editForm, {
    uuid: rec.uuid,
    name: rec.name,
    key: rec.key,
    type_id: rec.type_id || null,
    lead_id: rec.lead_id || null,
    status: rec.status || null,
    url: rec.url || ''
  })
  editOpen.value = true
}
function closeEdit() { editOpen.value = false }

async function submitEdit() {
  if (!editForm.uuid) return
  if (!editForm.name.trim()) { message.error('Please enter Name'); return }
  if (!editForm.key.trim())  { message.error('Please enter Key'); return }

  editLoading.value = true
  try {
    await axiosClient.patch('', {
      name: editForm.name.trim(),
      key: editForm.key.trim(),
      type_id: editForm.type_id || null,
      lead_id: editForm.lead_id || null,
      status: editForm.status || null,
      url: (editForm.url || '').trim() || null
    }, {
      params: { c: 'Space', m: 'update', uuid: editForm.uuid }
    })
    message.success('Updated')
    editOpen.value = false
    loadSpaces()
  } catch (err) {
    message.error(apiError(err, 'Update failed'))
  } finally {
    editLoading.value = false
  }
}

/* -------------------- UTIL -------------------- */
function apiError(err, fallback) {
  return err?.response?.data?.message || err?.message || fallback
}

/* -------------------- INIT -------------------- */
onMounted(async () => {
  await Promise.all([loadTypeOptions(), loadLeadOptions(), loadStatusOptions()])
  await loadSpaces()
})
</script>

<style scoped>
/* ===== Page ===== */
.page {
  padding: 20px;
  height: 690px;
  overflow-y: auto;
  background: linear-gradient(180deg, #fafbff 0%, #ffffff 60%);
  font-family: Inter, system-ui, -apple-system, Segoe UI, Roboto, "Helvetica Neue", Arial, "Noto Sans";
  color: #1f2937;
}

/* ===== Hero ===== */
.hero {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 16px;
  margin-bottom: 14px;
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
.hero-actions > *:not(:last-child) { margin-right: 8px; }

/* ===== Glass Panel ===== */
.glass {
  border-radius: 14px;
  background: rgba(255,255,255,0.7);
  backdrop-filter: blur(6px);
  border: 1px solid #eef2ff;
  box-shadow: 0 6px 24px rgba(99,102,241,0.08);
}

/* ===== Toolbar ===== */
.toolbar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px;
  margin-bottom: 12px;
}
.toolbar-input { width: 280px; }
.toolbar-select { width: 180px; }
.toolbar-select.wide { width: 240px; }
.divider { height: 20px; }
.dropdown-pane {
  background: #fff;
  padding: 10px 12px;
  border: 1px solid #eee;
  border-radius: 8px;
  min-width: 200px;
}
.dropdown-pane .row { margin: 6px 0; }
.spacer { flex: 1; }

/* ===== Table Wrap ===== */
.table-wrap {
  position: relative;
  padding: 8px;
}

/* Skeleton overlay */
.skeleton-overlay {
  position: absolute;
  inset: 0;
  padding: 12px;
  background: linear-gradient(180deg, rgba(255,255,255,0.55), rgba(255,255,255,0.75));
  backdrop-filter: blur(2px);
  z-index: 2;
  border-radius: 12px;
}
.skeleton-header {
  height: 36px;
  border-radius: 8px;
  margin-bottom: 8px;
  background: linear-gradient(90deg,#f3f4f6 25%,#eef2ff 37%,#f3f4f6 63%);
  background-size: 400% 100%;
  animation: shimmer 1.2s ease-in-out infinite;
}
.skeleton-row {
  height: 44px;
  border-radius: 6px;
  margin: 8px 0;
  background: linear-gradient(90deg,#f3f4f6 25%,#eef2ff 37%,#f3f4f6 63%);
  background-size: 400% 100%;
  animation: shimmer 1.2s ease-in-out infinite;
}
@keyframes shimmer { 0%{background-position: 200% 0} 100%{background-position: -200% 0} }
.fade-enter-active,.fade-leave-active{ transition: opacity .18s ease; }
.fade-enter-from,.fade-leave-to{ opacity: 0; }

/* ===== Ant table polish ===== */
.spaces-table :deep(.ant-table-thead > tr > th) {
  background: #fafafa;
  font-weight: 700;
}
.sortable { cursor: pointer; user-select: none; }
.sort-icon { font-size: 12px; opacity: .65; }

/* ===== Cells ===== */
.cell-name {
  display: flex; align-items: center; gap: 10px;
}
.avatar {
  width: 36px; height: 36px; border-radius: 10px;
  background: #eef2ff; color: #4f46e5;
  display: inline-flex; align-items: center; justify-content: center;
  font-weight: 800; letter-spacing: -0.02em;
}
.name-meta .strong { font-weight: 700; }
.link-like { color: #4f46e5; text-decoration: none; }
.link-like:hover { text-decoration: underline; }
.chips { display: flex; gap: 6px; margin-top: 2px; flex-wrap: wrap; }
.chip {
  display: inline-block; font-size: 12px; line-height: 18px; padding: 0 8px;
  background: #f3f4f6; border: 1px solid #e5e7eb; border-radius: 999px; color: #374151;
}
.chip.neutral { background: #eef2ff; border-color: #e5e7eb; color: #4f46e5; }

.lead { display: inline-flex; align-items: center; gap: 6px; }
.lead-name { white-space: nowrap; }

.mono { font-family: ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono",monospace; }
.badge { background: #f9fafb; border: 1px solid #e5e7eb; padding: 2px 6px; border-radius: 6px; }
.muted { color: #6b7280; }

/* Hover micro interaction */
.hover-rise-inline { transition: transform .12s ease; }
.hover-rise-inline:hover { transform: translateY(-1px); }

/* Empty state */
.empty-state {
  padding: 20px;
}

/* Pagination */
.pagination {
  display: flex;
  justify-content: center;
  margin-top: 12px;
}

/* Forms */
.row-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
@media (max-width: 560px) {
  .row-2 { grid-template-columns: 1fr; }
}
</style>
