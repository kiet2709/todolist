<template>
  <a-breadcrumb>
    <a-breadcrumb-item v-for="item in items" :key="item.path">
      <router-link v-if="item.path !== currentPath" :to="item.path">
        {{ item.title }}
      </router-link>
      <span v-else>{{ item.title }}</span>
    </a-breadcrumb-item>
  </a-breadcrumb>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

const routeMap = {
  '/': 'Trang chủ',
  '/users': 'Người dùng',
  '/users/roles': 'Phân quyền',
  '/projects': 'Dự án',
  '/projects/active': 'Đang hoạt động',
  '/projects/archived': 'Đã lưu trữ',
  '/settings': 'Cài đặt'
}

const items = computed(() => {
  const pathParts = route.path.split('/').filter(p => p)
  let currentPath = ''
  return pathParts.map(part => {
    currentPath += `/${part}`
    return {
      path: currentPath,
      title: routeMap[currentPath] || part
    }
  })
})

const currentPath = computed(() => route.path)
</script>

<style scoped>
:deep(.ant-breadcrumb) {
  font-size: 14px;
}

:deep(.ant-breadcrumb a) {
  color: #1890ff;
}
</style>