import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import router from './router'
import Antd from 'ant-design-vue'
import 'ant-design-vue/dist/reset.css'   // dùng file reset.css mới, không dùng style cũ
// hoặc nếu gặp lỗi thì dùng:
// import 'ant-design-vue/dist/antd.css'

const app = createApp(App)
app.use(router)
app.use(Antd)
app.mount('#app')
