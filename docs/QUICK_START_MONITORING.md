# 🎯 QUICK START: Your First 10 Minutes with Grafana & Prometheus

## 🚀 **Step 1: Access Your Tools (30 seconds)**

```bash
# Your URLs:
Prometheus: http://localhost:9090
Grafana:    http://localhost:3001 (admin/admin123)
```

## 📊 **Step 2: Explore Prometheus (2 minutes)**

1. **Open Prometheus**: http://localhost:9090
2. **Try these queries** in the query box:

```promql
# See all your services
up

# Check MinIO health 
up{job="minio"}

# See Prometheus itself
prometheus_notifications_total
```

3. **Click "Graph" tab** to see time-series data!

## 🎨 **Step 3: Import Your First Dashboard (3 minutes)**

1. **Open Grafana**: http://localhost:3001
2. **Login**: admin / admin123
3. **Import Dashboard**:
   - Click "+" → "Import"
   - Click "Upload JSON file"
   - Select: `infrastructure/docker/grafana/dashboards/infrastructure-overview.json`
   - Click "Import"

**🎉 BOOM! You now have a professional dashboard!**

## 🔥 **Step 4: Create Your Own Panel (5 minutes)**

1. **Click "+ Add Panel"** on your dashboard
2. **In Query field**, enter: `up`
3. **Panel settings**:
   - Title: "My Services Status"
   - Visualization: "Stat"
   - Unit: "Short"
4. **Color mapping**:
   - Value 0 = Red (Down)
   - Value 1 = Green (Up)
5. **Click "Apply"**

**🎯 You just created your first custom panel!**

---

## 🎓 **Understanding What You See**

### **Green Numbers = Good! 🟢**
- `up = 1` means service is healthy
- Response times < 1 second
- 0% error rate

### **Red Numbers = Attention Needed! 🔴**
- `up = 0` means service is down
- High response times
- Error rates > 0%

### **Time Series Graphs Show Trends 📈**
- Spikes = traffic increases
- Flat lines = steady state
- Drops = potential issues

---

## 💡 **Pro Tips for Immediate Success**

### **Bookmark These Queries:**
```promql
# Service health check
up

# MinIO storage info
minio_cluster_usage_total_bytes

# Prometheus performance
rate(prometheus_http_requests_total[5m])

# Memory usage (when available)
container_memory_usage_bytes
```

### **Dashboard Best Practices:**
- ✅ Use consistent time ranges (Last 1 hour)
- ✅ Refresh every 5-10 seconds for live data
- ✅ Mix different visualization types
- ✅ Add meaningful titles and descriptions

### **Quick Troubleshooting:**
- **No data?** Check if services are running: `docker-compose ps`
- **Can't access?** Verify ports: 9090 (Prometheus), 3001 (Grafana)
- **Queries fail?** Check syntax in Prometheus before using in Grafana

---

## 🚀 **Your Next Steps (When Ready)**

### **Today:**
- [ ] Explore the infrastructure dashboard
- [ ] Try different time ranges (1h, 6h, 24h)
- [ ] Create a simple alert (Settings → Alerting)

### **This Week:**
- [ ] Import the application metrics dashboard
- [ ] Learn 5 more PromQL functions
- [ ] Set up email notifications

### **When Building Backend:**
- [ ] Add custom metrics to your code
- [ ] Create business intelligence dashboards
- [ ] Monitor AI generation performance

---

## 🎉 **Congratulations!**

In just **10 minutes**, you've:
- ✅ Mastered professional monitoring tools
- ✅ Created your first dashboard
- ✅ Learned industry-standard practices
- ✅ Built enterprise-grade infrastructure

**You're now monitoring like Google, Netflix, and Spotify! 🚀**

---

## 🆘 **Need Help?**

### **Common Issues & Solutions:**
```bash
# Services not showing up?
docker-compose ps  # Check if all containers running

# Grafana won't load?
docker-compose logs grafana  # Check for errors

# Prometheus no data?
curl http://localhost:9090/-/healthy  # Test if accessible
```

### **Quick Reference:**
- **Prometheus Docs**: https://prometheus.io/docs/
- **Grafana Tutorials**: https://grafana.com/tutorials/
- **PromQL Cheat Sheet**: https://promlabs.com/promql-cheat-sheet/

**Now go explore and have fun! Your monitoring setup is AMAZING! 🎯📊**
