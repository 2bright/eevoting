import Vue from 'vue'
import Router from 'vue-router'

// in development-env not use lazy-loading, because lazy-loading too many pages will cause webpack hot update too slow. so only in production use lazy-loading;
// detail: https://panjiachen.github.io/vue-element-admin-site/#/lazy-loading

Vue.use(Router)

/* Layout */
import Layout from '../views/layout/Layout'

/**
* hidden: true                   if `hidden:true` will not show in the sidebar(default is false)
* alwaysShow: true               if set true, will always show the root menu, whatever its child routes length
*                                if not set alwaysShow, only more than one route under the children
*                                it will becomes nested mode, otherwise not show the root menu
* redirect: noredirect           if `redirect:noredirect` will no redirct in the breadcrumb
* name:'router-name'             the name is used by <keep-alive> (must set!!!)
* meta : {
    title: 'title'               the name show in submenu and breadcrumb (recommend set)
    icon: 'svg-name'             the icon show in the sidebar,
  }
**/
const routes = [
  {
    path: '/votings',
    component: Layout,
    children: [
      {
        path: 'mine',
        component: () => import('@/views/votings/mine'),
        meta: { title: '我的投票' }
      }
    ]
  },
  {
    path: '/votings',
    component: Layout,
    children: [
      {
        path: 'public',
        component: () => import('@/views/votings/public'),
        meta: { title: '公开投票' }
      }
    ]
  },
  {
    path: '/votings',
    component: Layout,
    children: [
      {
        path: 'usergroup',
        component: () => import('@/views/votings/usergroup'),
        meta: { title: '群投票' }
      }
    ]
  },
  {
    path: '/usergroups',
    component: Layout,
    children: [
      {
        path: '',
        component: () => import('@/views/usergroups'),
        meta: { title: '群' }
      }
    ]
  },
  {
    path: '/about',
    component: Layout,
    children: [
      {
        path: '',
        component: () => import('@/views/about'),
        meta: { title: '关于' }
      }
    ]
  },
  {
    path: '/votings',
    component: Layout,
    hidden: true,
    children: [
      {
        path: 'view/:id',
        component: () => import('@/views/votings/view.vue')
      },
      {
        path: 'new',
        component: () => import('@/views/votings/new.vue')
      }
    ]
  },
  {
    path: '/usergroups',
    component: Layout,
    hidden: true,
    children: [
      {
        path: 'view/:id',
        component: () => import('@/views/usergroups/view.vue')
      },
      {
        path: 'new',
        component: () => import('@/views/usergroups/new.vue')
      }
    ]
  },
  {
    path: '/404',
    component: Layout,
    hidden: true,
    children: [
      {
        path: '',
        component: () => import('@/views/404')
      }
    ]
  },
  {
    path: '/',
    redirect: '/votings/mine',
    hidden: true
  },
  {
    path: '*',
    redirect: '/404',
    hidden: true
  }
]

export default new Router({
  mode: 'history',
  routes
})
