<template>
  <a-layout-sider
    :collapsed="collapsed"
    :collapsible="true"
    :trigger="null"
    :width="256"
    :collapsedWidth="64"
    class="sidebar"
    @collapse="onCollapse"
  >
    <div class="sidebar-logo">
      <img v-if="!collapsed" src="../assets/logo.png" alt="Logo" class="logo-img" />
      <img v-else src="../assets/logo-icon.png" alt="Icon" class="logo-icon" />
    </div>

    <a-menu
      mode="inline"
      :selectedKeys="[currentRoute]"
      theme="light"
      @click="handleMenuClick"
    >
      <a-menu-item key="/home">
        <home-outlined />
        <span>Trang chủ</span>
      </a-menu-item>

      <a-sub-menu key="users">
        <template #title>
          <user-outlined />
          <span>Quản lý người dùng</span>
        </template>
        <a-menu-item key="/users">Danh sách</a-menu-item>
        <a-menu-item key="/users/roles">Phân quyền</a-menu-item>
      </a-sub-menu>

      <a-sub-menu key="projects">
        <template #title>
          <project-outlined />
          <span>Dự án</span>
        </template>
        <a-menu-item key="/projects/active">Đang hoạt động</a-menu-item>
        <a-menu-item key="/projects/archived">Đã lưu trữ</a-menu-item>
      </a-sub-menu>

      <a-menu-item key="/settings">
        <setting-outlined />
        <span>Cài đặt</span>
      </a-menu-item>
    </a-menu>
  </a-layout-sider>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import {
  HomeOutlined,
  UserOutlined,
  ProjectOutlined,
  SettingOutlined
} from '@ant-design/icons-vue'

const router = useRouter()
const route = useRoute()

const collapsed = ref(false)

const currentRoute = computed(() => route.path)

const handleMenuClick = ({ key }) => {
  router.push(key)
}

const onCollapse = (val) => {
  collapsed.value = val
}

// Theo dõi route để cập nhật menu active
watch(() => route.path, (path) => {
  // Có thể thêm logic highlight sub-menu nếu cần
})
</script>

<style scoped>
.sidebar {
  background: #fff;
  border-right: 1px solid #f0f0f0;
  height: 100vh;
  position: fixed;
  left: 0;
  top: 0;
  z-index: 999;
  overflow: auto;
}

.sidebar-logo {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px;
  border-bottom: 1px solid #f0f0f0;
}

.logo-img {
  height: 40px;
  object-fit: contain;
}

.logo-icon {
  height: 32px;
  object-fit: contain;
}

:deep(.ant-menu) {
  border-right: none !important;
}

:deep(.ant-menu-item),
:deep(.ant-menu-submenu-title) {
  margin: 4px 8px !important;
  border-radius: 8px !important;
}

:deep(.ant-menu-item-selected) {
  background: #e6f7ff !important;
  color: #1890ff !important;
}

:deep(.ant-menu-submenu-selected > .ant-menu-submenu-title) {
  color: #1890ff !important;
}
</style>