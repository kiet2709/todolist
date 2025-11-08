import { createRouter, createWebHistory } from 'vue-router'
import MainLayout from '../layouts/MainLayout.vue'
import HelloWorld from '../components/HelloWorld.vue'
import ListTasks from '../components/ListTasks.vue'
import SpaceManagement from '../components/SpaceManagement.vue'
import ListSpace from '../components/ListSpace.vue'

const routes = [
  {
    path: '/',
    component: MainLayout,
    children: [
      {
        path: '', // ← Quan trọng: path rỗng = chính là "/"
        redirect: '/home' // ← Tự động chuyển về /home
      },
      {
        path: 'home',
        name: 'home',
        component: HelloWorld
      },
        {
        path: 'tasks',
        name: 'tasks',
        component: ListTasks
      },
      {
        path: 'main',
        name: 'main',
        component: SpaceManagement
      },
      {
        path: 'spaces',
        name: 'spaces',
        component: ListSpace
      },
      // Thêm các route con khác ở đây sau này
    ]
  },

  // 404 fallback
  {
    path: '/:pathMatch(.*)*',
    redirect: '/home'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router