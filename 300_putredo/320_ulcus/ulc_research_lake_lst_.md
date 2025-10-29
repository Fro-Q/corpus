---
created: 2025-09-29
layer: putredo
status: probe
last_modified: 2025-09-29
---

*What lesion festers as a project—*
*what wound demands tending, yet resists closure?*

See MOC [here](../../200_neoplasma/220_vascula/vas_research_lake_lst_.md).

---

*Which tools, incisions, or neglects shape its course:*
*to suppurate, to scar, or to consume the flesh entire?*

- GEE 获取 MODIS LST 逐日数据，下载
- 机器学习部分用 Python 或 **Julia** 实现

---

*How shall this ulcer be tracked—*
*by the seepage it leaks, by the labour it devours,*
*or by the silence it leaves?*

## Log

### 10/22/25

- 重构：
  - 在这个项目中，重点不在于水体边界的精确提取，而在于如何高效地在大范围内提取湖泊的表层温度。
  - 湖泊可以被视为均一的水体单元，因此不需要确保所有的水体像元都被提取出来，而是要确保提取的像元确实属于水体。

---
