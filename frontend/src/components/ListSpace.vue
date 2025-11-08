<template>
  <div class="page">
    <div class="page-header">
      <h1 class="title">Spaces</h1>
      <div class="right-actions">
        <!-- <a-button type="default">Templates</a-button> -->
        <a-button type="primary" @click="openCreate">Create space</a-button>
      </div>
    </div>

    <!-- Toolbar -->
    <div class="toolbar">
      <a-input
        v-model:value="q"
        allow-clear
        placeholder="Search spaces"
        style="width: 260px"
        @change="goFirstPage"
      >
        <template #prefix>
          <svg width="16" height="16" viewBox="0 0 24 24">
            <path d="M11 4a7 7 0 015.292 11.708l3 3a1 1 0 11-1.414 1.414l-3-3A7 7 0 1111 4zm0 2a5 5 0 100 10 5 5 0 000-10z" fill="currentColor"/>
          </svg>
        </template>
      </a-input>

      <!-- (để nguyên comment filter Type theo yêu cầu của bạn) -->
      <a-select
        v-model:value="filters.type"
        :options="typeOptions"
        allow-clear
        placeholder="Filter by type"
        style="width: 180px"
        @change="goFirstPage"
      />

      <a-select
        v-model:value="filters.lead"
        :options="leadOptions"
        allow-clear
        placeholder="Lead"
        style="width: 160px"
        @change="goFirstPage"
      />
      <a-select
        v-model:value="filters.status"
        :options="statusOptions"
        allow-clear
        placeholder="Status"
        style="width: 140px"
        @change="goFirstPage"
      />

      <a-divider type="vertical" />
      <a-checkbox v-model:checked="onlyStarred" @change="goFirstPage">Starred</a-checkbox>
      <a-divider type="vertical" />

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

      <!-- (để nguyên comment Density theo yêu cầu của bạn) -->
      <!-- <a-dropdown trigger="click">
        <a-button>Density</a-button>
        <template #overlay>
          <div class="dropdown-pane">
            <a-radio-group v-model:value="density">
              <div class="row"><a-radio value="middle">Default</a-radio></div>
              <div class="row"><a-radio value="large">Comfortable</a-radio></div>
              <div class="row"><a-radio value="small">Compact</a-radio></div>
            </a-radio-group>
          </div>
        </template>
      </a-dropdown> -->

      <a-button @click="exportCSV">Export CSV</a-button>

      <div class="spacer"></div>

      <template v-if="selectedRowKeys.length">
        <a-button @click="bulkArchive(true)">Archive ({{ selectedRowKeys.length }})</a-button>
        <a-button @click="bulkArchive(false)">Unarchive</a-button>
        <a-popconfirm title="Delete selected?" ok-text="Delete" cancel-text="Cancel" @confirm="bulkDelete">
          <a-button danger>Delete</a-button>
        </a-popconfirm>
      </template>
    </div>

    <!-- Table -->
    <a-table
      :data-source="pagedData"
      :columns="tableColumns"
      :row-key="row => row.id"
      :pagination="false"
      :size="density"
      :row-selection="rowSelection"
      :customRow="customRow"
      class="spaces-table"
      bordered
    >
      <template #bodyCell="{ column, record, text }">
        <!-- Star -->
        <template v-if="column.key === 'star'">
          <a-tooltip :title="record.star ? 'Unstar' : 'Star'">
            <button class="star-btn" @click.stop="toggleStar(record)">
              <svg width="18" height="18" viewBox="0 0 24 24" :fill="record.star ? '#f59e0b' : 'none'" stroke="#f59e0b" stroke-width="1.7">
                <path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.62L12 2 9.19 8.62 2 9.24l5.46 4.73L5.82 21z"/>
              </svg>
            </button>
          </a-tooltip>
        </template>

        <!-- Name + icon -->
        <template v-else-if="column.key === 'name'">
          <div class="cell-name">
            <span class="space-icon" v-html="record.iconSvg"></span>
            <a class="link-like" @click.prevent="openSpace(record)">{{ record.name }}</a>
          </div>
        </template>

        <!-- Key -->
        <template v-else-if="column.key === 'key'">
          <code class="mono">{{ record.key }}</code>
        </template>

        <!-- Type -->
        <template v-else-if="column.key === 'type'">
          <a-tag :color="typeColorMap[record.type] || 'default'">{{ record.type }}</a-tag>
        </template>

        <!-- Lead -->
        <template v-else-if="column.key === 'lead'">
          <div class="lead">
            <a-avatar size="small" style="background:#5b67f1">{{ record.leadInitials }}</a-avatar>
            <span class="lead-name">{{ record.lead }}</span>
          </div>
        </template>

        <!-- Status -->
        <template v-else-if="column.key === 'status'">
          <a-tag :color="statusColor(record.status)">{{ record.status }}</a-tag>
        </template>

        <!-- Updated -->
        <template v-else-if="column.key === 'updatedAt'">
          <span class="muted">{{ formatDate(record.updatedAt) }}</span>
        </template>

        <!-- URL menu -->
        <template v-else-if="column.key === 'url'">
          <a-dropdown :trigger="['click']">
            <a-button shape="circle">⋯</a-button>
            <template #overlay>
              <a-menu>
                <a-menu-item @click="openSpace(record)">Open</a-menu-item>
                <a-menu-item @click="copyUrl(record)">Copy URL</a-menu-item>
                <a-menu-item @click="renameSpace(record)">Rename</a-menu-item>
                <a-menu-item @click="duplicateSpace(record)">Duplicate</a-menu-item>
                <a-menu-divider />
                <a-menu-item @click="toggleArchive(record)">
                  {{ record.archived ? 'Unarchive' : 'Archive' }}
                </a-menu-item>
                <a-menu-item danger @click="deleteSpace(record)">Delete</a-menu-item>
              </a-menu>
            </template>
          </a-dropdown>
        </template>

        <template v-else>
          {{ text }}
        </template>
      </template>
    </a-table>

    <!-- Pagination -->
    <div class="pagination">
      <a-pagination
        :current="page"
        :page-size="pageSize"
        :total="filteredSorted.length"
        show-size-changer
        :page-size-options="['5','10','20','50']"
        @change="(p, ps) => { page = p; pageSize = ps }"
        @showSizeChange="(p, ps) => { page = 1; pageSize = ps }"
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
          <a-form-item label="Type" :required="true">
            <a-select
              v-model:value="createForm.type"
              :options="typeOptions"
              placeholder="Select type"
            />
          </a-form-item>
        </div>

        <a-form-item label="Lead">
          <a-input v-model:value="createForm.lead" placeholder="Person in charge" />
        </a-form-item>

        <div class="row-3">
          <a-form-item label="Starred">
            <a-switch v-model:checked="createForm.star" />
          </a-form-item>
          <a-form-item label="Archived">
            <a-switch v-model:checked="createForm.archived" />
          </a-form-item>
          <a-form-item label="Auto URL from Key">
            <a-switch v-model:checked="autoUrl" />
          </a-form-item>
        </div>

        <a-form-item label="URL">
          <a-input v-model:value="createForm.url" placeholder="https://example.com/your-space" />
        </a-form-item>

        <a-alert type="info" show-icon message="Tip"
                 description="Key sẽ tự gợi ý từ Name (có thể sửa). URL được tạo từ Key nếu bật Auto URL."
                 style="margin-top: 6px;" />
      </a-form>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, reactive, computed, h, watch } from 'vue'
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
  Radio as ARadio,
  Pagination as APagination,
  Tooltip as ATooltip,
  Popconfirm as APopconfirm,
  Modal as AModal,
  Form as AForm,
  Switch as ASwitch,
  Alert as AAlert,
  message
} from 'ant-design-vue'
import 'ant-design-vue/dist/reset.css'

/* -------------------- ICON FACTORY -------------------- */
const makeIcon = (stroke, fill) => `
<svg width="20" height="20" viewBox="0 0 24 24" fill="none">
  <rect x="3" y="3" width="18" height="18" rx="3" stroke="${stroke}" stroke-width="1.5" fill="${fill}"/>
  <path d="M8 9h8M8 13h6" stroke="${stroke}" stroke-width="1.5" stroke-linecap="round"/>
</svg>`

const iconColorByType = (type) => {
  if (type === 'Service management') return { stroke: '#7B6A2B', fill: '#FFF6D6' }
  return { stroke: '#2B6A9B', fill: '#E9F6FF' } // Team-managed software
}

/* -------------------- MOCK DATA -------------------- */
const spacesRaw = ref([
  { id: 1,  star: true,  name: 'Support',            key: 'SUP', type: 'Service management', lead: 'Tuấn Kiệt Lê Nguyễn', leadInitials: 'TN', iconSvg: makeIcon('#7B6A2B','#FFF6D6'), status: 'Active',   url: 'https://example.com/sup', updatedAt: '2025-09-20', archived: false },
  { id: 2,  star: false, name: 'To Do List System',  key: 'KAN', type: 'Team-managed software', lead: 'Tuấn Kiệt Lê Nguyễn', leadInitials: 'TN', iconSvg: makeIcon('#2B6A9B','#E9F6FF'), status: 'Active', url: 'https://example.com/kan', updatedAt: '2025-09-18', archived: false },
  { id: 3,  star: false, name: 'Marketing Ops',     key: 'MKT', type: 'Service management', lead: 'Mai Trần', leadInitials: 'MT', iconSvg: makeIcon('#B91C1C','#FFECEC'), status: 'Active', url: 'https://example.com/mkt', updatedAt: '2025-08-11', archived: false },
  { id: 4,  star: true,  name: 'Finance Hub',       key: 'FIN', type: 'Team-managed software', lead: 'Lâm Phạm', leadInitials: 'LP', iconSvg: makeIcon('#6B21A8','#F5F3FF'), status: 'Active', url: 'https://example.com/fin', updatedAt: '2025-08-03', archived: false },
  { id: 5,  star: false, name: 'HR Portal',         key: 'HR',  type: 'Service management', lead: 'An Nguyễn', leadInitials: 'AN', iconSvg: makeIcon('#166534','#ECFDF5'), status: 'Active', url: 'https://example.com/hr', updatedAt: '2025-07-25', archived: false },
  { id: 6,  star: false, name: 'Design Board',      key: 'DSN', type: 'Team-managed software', lead: 'Yến Hà', leadInitials: 'YH', iconSvg: makeIcon('#D97706','#FEF3C7'), status: 'Active', url: 'https://example.com/dsn', updatedAt: '2025-07-12', archived: false },
  { id: 7,  star: false, name: 'IT Operations',     key: 'OPS', type: 'Service management', lead: 'Hải Đỗ', leadInitials: 'HĐ', iconSvg: makeIcon('#1E40AF','#E0F2FE'), status: 'Active', url: 'https://example.com/ops', updatedAt: '2025-07-07', archived: false },
  { id: 8,  star: false, name: 'Data Platform',     key: 'DPL', type: 'Team-managed software', lead: 'Trang Võ', leadInitials: 'TV', iconSvg: makeIcon('#2B6A9B','#E9F6FF'), status: 'Active', url: 'https://example.com/dpl', updatedAt: '2025-06-28', archived: false },
  { id: 9,  star: false, name: 'Customer Success',  key: 'CS',  type: 'Service management', lead: 'Long Phạm', leadInitials: 'LP', iconSvg: makeIcon('#7B6A2B','#FFF6D6'), status: 'Archived', url: 'https://example.com/cs', updatedAt: '2025-05-16', archived: true },
  { id:10,  star: false, name: 'QA Lab',            key: 'QAL', type: 'Team-managed software', lead: 'Huệ Đặng', leadInitials: 'HĐ', iconSvg: makeIcon('#6B21A8','#F5F3FF'), status: 'Active', url: 'https://example.com/qal', updatedAt: '2025-04-03', archived: false },
  { id:11,  star: false, name: 'Growth Sandbox',    key: 'GRW', type: 'Team-managed software', lead: 'Hùng Lê', leadInitials: 'HL', iconSvg: makeIcon('#D97706','#FEF3C7'), status: 'Active', url: 'https://example.com/grw', updatedAt: '2025-01-10', archived: false },
  { id:12,  star: false, name: 'Partner Portal',    key: 'PRT', type: 'Service management', lead: 'Quỳnh Anh', leadInitials: 'QA', iconSvg: makeIcon('#166534','#ECFDF5'), status: 'Active', url: 'https://example.com/prt', updatedAt: '2024-12-01', archived: false }
])

/* -------------------- FILTERS / STATE -------------------- */
const q = ref('')
const filters = ref({ type: null, lead: null, status: null })
const onlyStarred = ref(false)

const typeOptions = [
  { label: 'Service management', value: 'Service management' },
  { label: 'Team-managed software', value: 'Team-managed software' }
]
const leadOptions = computed(() =>
  Array.from(new Set(spacesRaw.value.map(s => s.lead))).map(v => ({ label: v, value: v }))
)
const statusOptions = [
  { label: 'Active', value: 'Active' },
  { label: 'Archived', value: 'Archived' }
]

const typeColorMap = {
  'Service management': 'gold',
  'Team-managed software': 'blue'
}
const statusColor = s => (s === 'Active' ? 'green' : 'default')

/* -------------------- COLUMNS -------------------- */
const columnLabels = {
  star: '',
  name: 'Name',
  key: 'Key',
  type: 'Type',
  lead: 'Lead',
  status: 'Status',
  updatedAt: 'Updated',
  url: 'Space URL'
}
const allColumnKeys = ['star', 'name', 'key', 'type', 'lead', 'status', 'updatedAt', 'url']
const visibleColsSet = ref(new Set(allColumnKeys))
const toggleColumn = (key) => {
  const set = new Set(visibleColsSet.value)
  if (set.has(key)) set.delete(key)
  else set.add(key)
  if (![...set].some(k => ['name','key','type','lead','status','updatedAt'].includes(k))) return
  visibleColsSet.value = set
}

/* sorting */
const sortState = ref({ key: 'name', order: 'asc' })
const onHeaderSort = (key) => {
  if (sortState.value.key === key) {
    sortState.value.order = sortState.value.order === 'asc' ? 'desc' : 'asc'
  } else {
    sortState.value = { key, order: 'asc' }
  }
}

/* density (giữ nguyên binding size) */
const density = ref('middle')

/* selection (reactive) */
const selectedRowKeys = ref([])
const rowSelection = computed(() => ({
  selectedRowKeys: selectedRowKeys.value,
  onChange: (keys) => { selectedRowKeys.value = keys }
}))
const customRow = (record) => ({
  onClick: () => {
    const idx = selectedRowKeys.value.indexOf(record.id)
    if (idx >= 0) selectedRowKeys.value.splice(idx, 1)
    else selectedRowKeys.value.push(record.id)
  }
})

/* -------------------- DERIVED DATA -------------------- */
const filteredSorted = computed(() => {
  let arr = spacesRaw.value.slice()

  if (q.value.trim()) {
    const s = q.value.trim().toLowerCase()
    arr = arr.filter(x =>
      x.name.toLowerCase().includes(s) ||
      String(x.key).toLowerCase().includes(s)
    )
  }
  if (filters.value.type)   arr = arr.filter(x => x.type === filters.value.type)
  if (filters.value.lead)   arr = arr.filter(x => x.lead === filters.value.lead)
  if (filters.value.status) arr = arr.filter(x => (filters.value.status === 'Archived') ? x.archived : !x.archived)
  if (onlyStarred.value) arr = arr.filter(x => x.star)

  const { key, order } = sortState.value
  arr.sort((a,b) => {
    const va = a[key]
    const vb = b[key]
    let cmp = 0
    if (key === 'updatedAt') {
      cmp = new Date(a.updatedAt) - new Date(b.updatedAt)
    } else {
      cmp = String(va).localeCompare(String(vb), 'en', { numeric:true, sensitivity:'base' })
    }
    return order === 'asc' ? cmp : -cmp
  })
  return arr
})

/* pagination */
const page = ref(1)
const pageSize = ref(10)
const goFirstPage = () => { page.value = 1 }
const pagedData = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return filteredSorted.value.slice(start, start + pageSize.value)
})

/* columns for a-table */
const tableColumns = computed(() => {
  const cols = []
  if (visibleColsSet.value.has('star')) cols.push({ title: '', dataIndex: 'star', key: 'star', width: 46 })
  if (visibleColsSet.value.has('name')) cols.push(sortableHeader('Name', 'name'))
  if (visibleColsSet.value.has('key'))  cols.push(sortableHeader('Key', 'key', 110))
  if (visibleColsSet.value.has('type')) cols.push(sortableHeader('Type', 'type', 200))
  if (visibleColsSet.value.has('lead')) cols.push(sortableHeader('Lead', 'lead', 220))
  if (visibleColsSet.value.has('status')) cols.push(sortableHeader('Status', 'status', 120))
  if (visibleColsSet.value.has('updatedAt')) cols.push(sortableHeader('Updated', 'updatedAt', 140))
  if (visibleColsSet.value.has('url'))  cols.push({ title: 'Space URL', key: 'url', align: 'right', width: 80 })
  return cols
})

function sortableHeader(titleText, key, width) {
  const active = sortState.value.key === key
  const dir = sortState.value.order
  const icon = active ? (dir === 'asc' ? '↑' : '↓') : '↕'
  return {
    title: () => h('span', { class: 'sortable', onClick: () => onHeaderSort(key) }, [
      titleText, ' ', h('span', { class: 'sort-icon' }, icon)
    ]),
    dataIndex: key,
    key,
    width
  }
}

/* -------------------- ACTIONS (table) -------------------- */
function openSpace(row) {
  window.open(row.url, '_blank')
}
function copyUrl(row) {
  navigator.clipboard.writeText(row.url)
  message.success('Copied URL')
}
function renameSpace(row) {
  const name = window.prompt('New name', row.name)
  if (name && name.trim()) {
    row.name = name.trim()
    message.success('Renamed')
  }
}
function duplicateSpace(row) {
  const id = Math.max(...spacesRaw.value.map(x => x.id)) + 1
  const clone = { ...row, id, star: false, key: uniqueKey(row.key), name: row.name + ' (Copy)', updatedAt: today() }
  spacesRaw.value.unshift(clone)
  message.success('Duplicated')
}
function uniqueKey(base) {
  let k = base
  let i = 1
  const set = new Set(spacesRaw.value.map(s => s.key))
  while (set.has(k)) { k = `${base}${i}`; i++ }
  return k
}
function toggleArchive(row) {
  row.archived = !row.archived
  row.status = row.archived ? 'Archived' : 'Active'
  row.updatedAt = today()
}
function deleteSpace(row) {
  spacesRaw.value = spacesRaw.value.filter(s => s.id !== row.id)
  selectedRowKeys.value = selectedRowKeys.value.filter(id => id !== row.id)
  message.success('Deleted')
}
function toggleStar(row) {
  row.star = !row.star
}

/* bulk */
function bulkArchive(archive) {
  spacesRaw.value.forEach(s => {
    if (selectedRowKeys.value.includes(s.id)) {
      s.archived = archive
      s.status = archive ? 'Archived' : 'Active'
      s.updatedAt = today()
    }
  })
  message.success(archive ? 'Archived selected' : 'Unarchived selected')
}
function bulkDelete() {
  spacesRaw.value = spacesRaw.value.filter(s => !selectedRowKeys.value.includes(s.id))
  selectedRowKeys.value = []
  message.success('Deleted selected')
}

/* export */
function exportCSV() {
  const rows = filteredSorted.value
  const header = ['Starred','Name','Key','Type','Lead','Status','Updated','URL']
  const data = rows.map(r => [r.star ? 'Yes':'No', r.name, r.key, r.type, r.lead, r.status, r.updatedAt, r.url])
  const csv = [header, ...data].map(r => r.map(escapeCSV).join(',')).join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = `spaces_${Date.now()}.csv`
  a.click()
  URL.revokeObjectURL(a.href)
}
const escapeCSV = (v) => {
  const s = String(v ?? '')
  return /[",\n]/.test(s) ? `"${s.replace(/"/g,'""')}"` : s
}

/* utils */
const today = () => new Date().toISOString().slice(0,10)
function formatDate(d) {
  try { return new Date(d).toLocaleDateString() } catch { return d }
}
function initialsFromName(fullName) {
  if (!fullName) return ''
  const parts = fullName.trim().split(/\s+/)
  if (parts.length === 1) return parts[0].slice(0,2).toUpperCase()
  return (parts[0][0] + parts[parts.length-1][0]).toUpperCase()
}
function keyFromName(name) {
  if (!name) return ''
  const words = name.replace(/[^\p{L}\p{N}\s]/gu,' ').split(/\s+/).filter(Boolean)
  let key = words.length > 1 ? words.map(w => w[0]).join('') : words[0].slice(0,3)
  key = key.toUpperCase().slice(0,10)
  return key
}
function urlFromKey(k) {
  if (!k) return ''
  return `https://example.com/${k.toLowerCase()}`
}

/* -------------------- CREATE MODAL STATE -------------------- */
const createOpen = ref(false)
const createLoading = ref(false)
const autoUrl = ref(true)
const createForm = reactive({
  name: '',
  key: '',
  type: 'Service management',
  lead: '',
  star: false,
  archived: false,
  url: ''
})
function openCreate() {
  // reset form
  Object.assign(createForm, { name: '', key: '', type: 'Service management', lead: '', star: false, archived: false, url: '' })
  autoUrl.value = true
  createOpen.value = true
}
function closeCreate() {
  createOpen.value = false
}

watch(() => createForm.name, (val) => {
  // gợi ý key theo name, đảm bảo unique khi submit
  const guess = keyFromName(val)
  if (!createForm.key || createForm.key === guess.slice(0, createForm.key.length)) {
    createForm.key = guess
  }
  if (autoUrl.value) createForm.url = urlFromKey(createForm.key)
})
watch(() => createForm.key, (val) => {
  if (autoUrl.value) createForm.url = urlFromKey(val)
})

async function submitCreate() {
  // validate tối thiểu
  if (!createForm.name.trim()) { message.error('Please enter Name'); return }
  if (!createForm.key.trim())  { message.error('Please enter Key'); return }
  if (!createForm.type)        { message.error('Please select Type'); return }

  createLoading.value = true
  try {
    // unique key
    const finalKey = uniqueKey(createForm.key.toUpperCase())
    const { stroke, fill } = iconColorByType(createForm.type)
    const id = Math.max(0, ...spacesRaw.value.map(s => s.id)) + 1
    const newItem = {
      id,
      star: !!createForm.star,
      name: createForm.name.trim(),
      key: finalKey,
      type: createForm.type,
      lead: createForm.lead.trim() || 'Unassigned',
      leadInitials: initialsFromName(createForm.lead.trim() || 'Unassigned'),
      iconSvg: makeIcon(stroke, fill),
      archived: !!createForm.archived,
      status: createForm.archived ? 'Archived' : 'Active',
      url: createForm.url.trim() || urlFromKey(finalKey),
      updatedAt: today()
    }
    spacesRaw.value.unshift(newItem)
    message.success('Space created')
    createOpen.value = false
    goFirstPage()
  } finally {
    createLoading.value = false
  }
}
</script>

<style scoped>
.page {
  padding: 20px;
  background: #fff;
  font-family: Inter, system-ui, -apple-system, Segoe UI, Roboto, "Helvetica Neue", Arial, "Noto Sans", "Apple Color Emoji","Segoe UI Emoji";
  color: #222;
  height: 690px;         /* theo cấu hình bạn đã thêm */
  overflow-y: auto;      /* theo cấu hình bạn đã thêm */
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}
.title { font-size: 28px; font-weight: 700; }
.right-actions > *:not(:last-child) { margin-right: 8px; }

.toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}
.spacer { flex: 1; }

.dropdown-pane {
  background: #fff;
  padding: 10px 12px;
  border: 1px solid #eee;
  border-radius: 8px;
  min-width: 180px;
}
.dropdown-pane .row { margin: 6px 0; }

.spaces-table :deep(.ant-table-thead > tr > th) { background: #fafafa; }
.sortable { cursor: pointer; user-select: none; }
.sort-icon { font-size: 12px; opacity: .65; }

.cell-name { display: flex; align-items: center; gap: 8px; }
.space-icon { width: 20px; height: 20px; display: inline-block; }
.link-like { color: #1677ff; text-decoration: none; cursor: pointer; }

.lead { display: inline-flex; align-items: center; gap: 6px; }
.lead-name { white-space: nowrap; }

.star-btn {
  border: none; background: transparent; cursor: pointer; padding: 0; line-height: 0;
}

.mono { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace; }
.muted { color: #6b7280; }

.pagination { display: flex; justify-content: center; margin-top: 12px; }

/* Modal layout helpers */
.row-2, .row-3 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
.row-3 { grid-template-columns: 1fr 1fr 1fr; }
@media (max-width: 560px) {
  .row-2, .row-3 { grid-template-columns: 1fr; }
}
</style>
