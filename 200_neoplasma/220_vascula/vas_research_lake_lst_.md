---
created: 2025-09-29
layer: neoplasma
status: probe
last_modified: 2025-09-29
bibliography: /Users/oQ/3_resources/research/refs/zotero.bib
---

一项关于湖泊的陆表温度提取方法的研究。

*Which disparate vessels dost thou stitch together here,*
*grafting vein to vein across impossible distances?*  

## Keys

- ~~大津算法（或者其他阈值算法）~~
- ~~计算机视觉（not really）~~
- Google Earth Engine
- Python
- Landsat (for water body extraction)
  - [x] (Why not landsat lst but modis?) Need day scale 
- MODIS LST
  - on [Earth Engine](https://developers.google.com/earth-engine/datasets/catalog/MODIS_061_MOD11A1)
  - User's Guide: @modis_lst_ug
  - [General Documentation](https://ladsweb.modaps.eosdis.nasa.gov/filespec/MODIS/61/MOD11A1)
  - Algorithm Theoretical Basis Document (ATBD): @modis_lst_atbd

重点并非水体边界提取，而是如何在大范围内高效地提取湖泊表层温度。

湖泊可以看作均一水体单元，故并不需要严格保证所有的水体像元均被提取，而是需要保证提取的水体像元均为水体。

---

*What alien circulation begins when these connections pulse—*
*does it nourish, infect, or clot the Corpus?*  

---

*Shall this linkage endure as structure,*
*or rupture as a sudden aneurysm in the web of thought?*

---
