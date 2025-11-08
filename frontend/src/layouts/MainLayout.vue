<template>
  <a-layout class="main-layout">
    <!-- Sidebar -->
    <Sidebar v-model:collapsed="sidebarCollapsed" />

    <!-- Main Area -->
    <a-layout :style="{ marginLeft: sidebarCollapsed ? '64px' : '256px', transition: 'margin 0.2s' }">
      <!-- Topbar -->
      <Topbar :sidebar-collapsed="sidebarCollapsed" @toggle-sidebar="toggleSidebar" />

      <!-- Content -->
      <a-layout-content class="content">
        <div class="content-inner" :style="{ width: sidebarCollapsed ? 'calc(100vw - 64px)' : 'calc(100vw - 256px)', transition: 'margin 0.2s' }" >
          <router-view />
        </div>
      </a-layout-content>
    </a-layout>
  </a-layout>
</template>

<script setup>
import { ref } from 'vue'
import Sidebar from '../components/Sidebar.vue'
import Topbar from '../components/Topbar.vue'

const sidebarCollapsed = ref(false)

const toggleSidebar = () => {
  sidebarCollapsed.value = !sidebarCollapsed.value
}
</script>

<style scoped>
.main-layout {
  height: 100vh;
  overflow: hidden;
}

.content {
  background: #f9f9f9;
  min-height: calc(100vh - 64px - 48px);
  overflow: auto;
}

.content-inner {
  background: #fff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  height: 100vh;
  /* width: calc(100vw - 256px); */
}
</style>