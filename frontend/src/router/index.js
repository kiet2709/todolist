import { createRouter, createWebHistory } from 'vue-router'
import MainLayout from '../layouts/MainLayout.vue'
import HelloWorld from '../components/HelloWorld.vue'
import TaskDetail from '../components/TaskDetail.vue'
import CreateTask from '../components/CreateTask.vue'
import Dashboard from '../components/Dashboard.vue'
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
      {
        path: 'detail',
        name: 'detail',
        component: TaskDetail
      },
      {
        path: 'create-task',
        name: 'Create Task',
        component: CreateTask
      },
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: Dashboard
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