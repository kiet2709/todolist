<template>
  <a-layout-header class="topbar">
    <div class="topbar-left">
      <menu-unfold-outlined
        v-if="sidebarCollapsed"
        class="trigger"
        @click="toggleSidebar"
      />
      <menu-fold-outlined
        v-else
        class="trigger"
        @click="toggleSidebar"
      />
      <breadcrumb />
    </div>

    <div class="topbar-right">
      <a-dropdown :trigger="['click']">
        <div class="user-info">
          <a-avatar :size="36" style="background: #1890ff">
            {{ userInitial }}
          </a-avatar>
          <span class="user-name">{{ user.name }}</span>
        </div>
        <template #overlay>
          <a-menu>
            <a-menu-item @click="goToProfile">
              <user-outlined /> Hồ sơ
            </a-menu-item>
            <a-menu-item @click="handleLogout">
              <logout-outlined /> Đăng xuất
            </a-menu-item>
          </a-menu>
        </template>
      </a-dropdown>
    </div>
  </a-layout-header>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import {
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  UserOutlined,
  LogoutOutlined
} from '@ant-design/icons-vue'
import Breadcrumb from './Breadcrumb.vue'

const router = useRouter()

// Giả lập user
const user = {
  name: 'Nguyễn Văn A',
  role: 'Admin'
}

const userInitial = computed(() => user.name.charAt(0).toUpperCase())

defineProps({
  sidebarCollapsed: Boolean
})

const emit = defineEmits(['toggle-sidebar'])

const toggleSidebar = () => {
  emit('toggle-sidebar')
}

const goToProfile = () => {
  router.push('/profile')
}

const handleLogout = () => {
  localStorage.removeItem('token')
  router.push('/login')
}
</script>

<style scoped>
.topbar {
  background: #fff;
  padding: 0 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #f0f0f0;
  height: 64px;
  line-height: 64px;
  position: sticky;
  top: 0;
  z-index: 998;
  box-shadow: 0 1px 4px rgba(0, 15, 15, 0.04);
}

.topbar-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.trigger {
  font-size: 18px;
  cursor: pointer;
  transition: color 0.3s;
}

.trigger:hover {
  color: #1890ff;
}

.topbar-right {
  display: flex;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.user-name {
  font-weight: 500;
  color: #262626;
}
</style>