import axios from 'axios'

const apiClient = axios.create({
  baseURL: '/mock-api',
  timeout: 1200,
})

apiClient.interceptors.request.use((config) => {
  return config
})

apiClient.interceptors.response.use(
  (response) => response,
  (error) => Promise.reject(error),
)

export default apiClient
