import { createRouter, createWebHistory } from 'vue-router'
import MainLayout from '../layouts/MainLayout.vue'
import HelloWorld from '../components/HelloWorld.vue'

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
        path: 'hello',
        name: 'hello',
        component: HelloWorld
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