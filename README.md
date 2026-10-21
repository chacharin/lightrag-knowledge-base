# LightRAG-Knowledge-Base

คลังความรู้พร้อมใช้งานที่สร้างบน [LightRAG](https://github.com/HKUDS/LightRAG) ประกอบด้วยหน้าเว็บภาษาไทยและอังกฤษสำหรับจัดการเอกสาร ดูกราฟความรู้ และถามตอบ
พร้อม MCP server ([mcp-lightrag](https://github.com/chacharin/mcp-lightrag)) ให้เอเจนต์ AI ค้นหาและเพิ่มเอกสารได้ ติดตั้งด้วย Docker Compose คำสั่งเดียว

ผู้พัฒนา: **Chacharin Lertyosbordin**

> repo นี้ไม่ได้รวมตัว LightRAG มาด้วย แต่ใช้ image ทางการ `ghcr.io/hkuds/lightrag:v1.5.7` และแทนที่หน้าเว็บด้วยฉบับดัดแปลงใน `webui/`
> LightRAG พัฒนาโดย HKUDS ภายใต้สัญญาอนุญาต MIT (ดู [NOTICE.md](NOTICE.md)) และโปรเจกต์นี้ไม่ใช่ผลงานทางการของ HKUDS

## ส่วนประกอบ

| ส่วน | มาจาก | หน้าที่ |
|---|---|---|
| `lightrag` | image ทางการของ LightRAG v1.5.7 | เก็บเอกสาร สร้างกราฟความรู้ ตอบคำถาม และให้บริการ REST API กับหน้าเว็บ (พอร์ต 9621) |
| `webui/` | repo นี้ (ดัดแปลงจากหน้าเว็บของ LightRAG v1.5.7) | หน้าเว็บคลังความรู้ที่ `http://<เครื่อง>:9621/webui/` |
| `mcp-lightrag` | build จาก [github.com/chacharin/mcp-lightrag](https://github.com/chacharin/mcp-lightrag) | MCP server สำหรับเอเจนต์ AI (พอร์ต 8806) และมิเตอร์ที่บันทึก token ทุกครั้งที่ LightRAG เรียก LLM |
| `data/` | การติดตั้งของคุณ | เอกสาร เวกเตอร์ และกราฟความรู้ (เริ่มต้นว่าง ไม่ถูกส่งขึ้น git) |

## หน้าเว็บ

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│ คลังความรู้                                                               [TH] [EN] │
│ LightRAG: ระบบสร้างคำตอบจากการค้นคืนข้อมูลและกราฟความรู้                                 │
├──────────────────┬───────────────────────────────────────────┬────────────────────┤
│ เชื่อมต่อจาก       │ [เอกสาร] [กราฟความรู้] [การสืบค้น]  ● เชื่อมต่อแล้ว │ ถามคลังความรู้        │
│ ระบบภายนอก   «   │                                           │                 »  │
│                  │   จัดการเอกสาร / ดูกราฟความรู้ / ถามตอบ        │  โหมดการค้น: mix …  │
│ MCP | REST API   │   แบบละเอียด (หน้าเดิมของ LightRAG)         │                    │
│ endpoint, key,   │                                           │  แชตถามตอบ          │
│ ตัวอย่างโค้ด         │                                           │  พร้อมแหล่งอ้างอิง     │
│ ● LightRAG ● MCP │                                           │  [ พิมพ์คำถาม ] [ส่ง] │
└──────────────────┴───────────────────────────────────────────┴────────────────────┘
```

- **แถบบน** มีปุ่มเปลี่ยนภาษา TH / EN 
- **แถบซ้าย "เชื่อมต่อจากระบบภายนอก"** บอกวิธีให้ระบบอื่นใช้คลังนี้ 2 ช่องทาง พร้อม endpoint key และตัวอย่างที่คัดลอกไปใช้ได้ทันที
  - **MCP** สำหรับเอเจนต์ AI เช่น Hermes, Claude หรือ Cursor มีตัวอย่างการตั้งค่าของแต่ละโปรแกรม
  - **REST API** สำหรับแอปหรือสคริปต์ มีตัวอย่าง curl, PowerShell, Python และ JavaScript และลิงก์ไปเอกสาร API ทั้งหมด
- **กลาง** ส่วนจัดการเอกสาร ดูกราฟความรู้ และหน้าสืบค้นแบบละเอียดที่ปรับค่าการค้นได้ทุกค่า
- **แถบขวา "ถามคลังความรู้"** ส่วนแชตถามตอบที่ใช้ได้จากทุกแท็บ เลือกโหมดการค้นได้ และแยกประวัติการสนทนาจากหน้าสืบค้น

## หลักการทำงาน

```
เบราว์เซอร์ ──:9621/webui──▶ lightrag ◀──REST /query (X-API-Key)── แอปหรือสคริปต์
                              │  ▲
             LLM และ embedding │  │ LIGHTRAG_API_KEY
                              ▼  │
เอเจนต์ AI ──:8806/mcp──▶ mcp-lightrag ──/meter──▶ ผู้ให้บริการ LLM (METER_UPSTREAM เช่น OpenRouter)
                              │
                              └── GET /usage: token เวลา และค่าใช้จ่ายของทุกการเรียก
```

- เอเจนต์เรียกเครื่องมือผ่าน mcp-lightrag ซึ่งถือ `LIGHTRAG_API_KEY` ไว้เอง เอเจนต์จึงไม่ต้องรู้ key ของ LightRAG
- LightRAG เรียก LLM และ embedding ผ่าน**มิเตอร์**ของ mcp-lightrag ซึ่งส่งคำขอต่อไปยังผู้ให้บริการโดยไม่แก้ไข แล้วบันทึกจำนวน token ไว้
  เพราะ LightRAG ไม่รายงาน token ของตัวเอง ทั้งที่คำถามหนึ่งข้อเรียก LLM 2 ครั้งกับ embedding 1 ครั้ง และการเพิ่มเอกสารเรียกอีกหลายครั้ง

## เริ่มต้นใช้งาน

### สิ่งที่ต้องเตรียม

- **Docker** พร้อม Docker Compose v2 และการเชื่อมต่ออินเทอร์เน็ตระหว่างติดตั้งครั้งแรก (ดาวน์โหลด image ของ LightRAG และ build mcp-lightrag จาก GitHub)
- **API key ของผู้ให้บริการ LLM แบบ OpenAI-compatible** เช่น [OpenRouter](https://openrouter.ai/keys) ที่มีทั้ง LLM และ embedding model

### ขั้นตอนการติดตั้ง

```bash
git clone https://github.com/chacharin/lightrag-knowledge-base.git
cd lightrag-knowledge-base
cp .env.example .env                  # จากนั้นแก้ LIGHTRAG_API_KEY, LLM_BINDING_API_KEY และ EMBEDDING_BINDING_API_KEY
docker network create agent_network   # สร้างครั้งแรกครั้งเดียว หากต้องการใช้ชื่ออื่นให้กำหนดใน DOCKER_NETWORK
docker compose up -d --build
```

`LIGHTRAG_API_KEY` ควรเป็นค่าสุ่มที่ยาว สร้างได้ด้วย `python -c "import secrets; print(secrets.token_urlsafe(32))"`

ตรวจสถานะ:

```bash
curl http://127.0.0.1:9621/health     # LightRAG: "status": "healthy"
curl http://127.0.0.1:8806/health     # mcp-lightrag: "ok": true และ "meter": {"enabled": true, …}
```

จากนั้นเปิด `http://<เครื่อง>:9621/webui/` ใส่ `LIGHTRAG_API_KEY` ในหน้าต่างที่ขึ้นมา (เบราว์เซอร์จะจำไว้) แล้วอัปโหลดเอกสารในแท็บ "เอกสาร"
LightRAG สร้างกราฟความรู้ในเบื้องหลัง เมื่อสถานะของเอกสารเป็น "เสร็จสมบูรณ์" จึงถามจากแถบขวาได้

## การเชื่อมต่อจากระบบภายนอก

แถบซ้ายของหน้าเว็บแสดงทุกอย่างในหัวข้อนี้พร้อมปุ่มคัดลอก

| ช่องทาง | ที่อยู่ | ยืนยันตัวตน | เหมาะกับ |
|---|---|---|---|
| MCP | `http://<เครื่อง>:8806/mcp` (streamable HTTP) | header `Authorization: Bearer <MCP_AUTH_TOKEN>` เฉพาะเมื่อกำหนดไว้ | เอเจนต์ AI ที่รองรับ MCP |
| REST API | `http://<เครื่อง>:9621/query` (POST JSON) | header `X-API-Key: <LIGHTRAG_API_KEY>` | แอปและสคริปต์ |

**MCP** มีเครื่องมือ `lightrag_query`, `lightrag_insert`, `lightrag_list_documents` และ `lightrag_delete` (เมื่อ `ENABLE_DELETE=true`) รายละเอียดอยู่ใน [README ของ mcp-lightrag](https://github.com/chacharin/mcp-lightrag)
ตัวอย่างการตั้งค่าใน Hermes:

```yaml
mcp_servers:
  lightrag:
    url: http://mcp-lightrag:8700/mcp   # เอเจนต์ใน docker network เดียวกัน · เครื่องอื่นใช้ http://<เครื่อง>:8806/mcp
    timeout: 180
```

**REST API** ตัวอย่างคำขอและผลลัพธ์:

```json
{"query": "สรุปเอกสารในคลังโดยย่อ", "mode": "mix", "include_references": true,
 "conversation_history": [{"role": "user", "content": "…"}, {"role": "assistant", "content": "…"}]}
```

```json
{"response": "…", "references": [{"reference_id": "1", "file_path": "report.pdf", "content": null}], "response_time": 4.2}
```

`mode` มี `mix` `hybrid` `local` `global` `naive` · `conversation_history` ใช้ถามต่อจากบทสนทนาเดิม · ถ้าต้องการรับคำตอบทีละส่วนให้ใช้ `POST /query/stream` (NDJSON)
endpoint ทั้งหมด เช่น อัปโหลดเอกสาร (`POST /documents/upload`) และดูกราฟ ดูได้ที่ `http://<เครื่อง>:9621/docs`

ที่อยู่ MCP ที่แถบซ้ายแสดงคือ `<ชื่อเครื่องในแถบที่อยู่ของเบราว์เซอร์>:8806/mcp` หากเปลี่ยนพอร์ตหรือใช้ reverse proxy ให้แก้ไฟล์ `webui/kb-config.js` บนเครื่อง (ไม่ต้อง build ใหม่):

```js
window.__KB_CONFIG__ = {
  mcpUrl: "https://kb.example.com/mcp",   // null = ใช้ชื่อเครื่องเดียวกับหน้าเว็บ + mcpPort
  mcpPort: 8806,
};
```

## ข้อมูลการใช้งาน (token และเวลา)

`GET http://<เครื่อง>:8806/usage?since=<epoch>` คืนบันทึ(Log)ที่เกิดจากการใช้งานของทุกการเรียกเครื่องมือ และทุกครั้งที่ LightRAG เรียก LLM หรือ embedding ผ่านมิเตอร์
ได้แก่ token ขาเข้า ขาออก และที่อ่านจาก cache ค่าใช้จ่ายที่ผู้ให้บริการรายงาน และเวลา โดยไม่มีเนื้อหาเอกสารหรือคำถาม

หากไม่ต้องการมิเตอร์ ให้ตั้ง `LLM_BINDING_HOST` และ `EMBEDDING_BINDING_HOST` ใน `.env` เป็นที่อยู่ของผู้ให้บริการโดยตรง แล้วสั่ง `docker compose restart lightrag`
เมื่อใช้มิเตอร์ LightRAG จะเรียก LLM ได้เฉพาะตอนที่ mcp-lightrag ทำงานอยู่

## การปรับให้เหมาะกับคลังของคุณ

ค่าต่อไปนี้อยู่ในไฟล์ `.env` (คำอธิบายทุกตัวแปรอยู่ใน [`.env.example`](.env.example)) แก้แล้วสั่ง `docker compose up -d` และ `docker compose restart lightrag`

- **`WEBUI_TITLE` และ `WEBUI_DESCRIPTION`** ชื่อคลังที่แสดงต่อท้าย "คลังความรู้" และคำอธิบายเมื่อชี้เมาส์ เช่น `WEBUI_TITLE=คู่มือผลิตภัณฑ์`
- **`KB_DESCRIPTION`** บอกเอเจนต์ว่าคลังนี้เก็บเรื่องอะไร เพื่อให้เลือกค้นคลังนี้ได้ถูกจังหวะ
- **`SUMMARY_LANGUAGE`** ภาษาที่ LightRAG ใช้สรุปเอนทิตีและความสัมพันธ์ในกราฟ
- **`LLM_MODEL`, `EMBEDDING_MODEL` และ `EMBEDDING_DIM`** model ที่ใช้ หากเปลี่ยน embedding model หลังเพิ่มเอกสารแล้ว ต้องเริ่มคลังใหม่ (ล้าง `data/rag_storage/`)
- **ผู้ให้บริการอื่นแทน OpenRouter** ตั้ง `METER_UPSTREAM` เป็น endpoint ของผู้ให้บริการนั้น (เช่น `https://api.openai.com/v1`) พร้อม API key และชื่อ model ที่ตรงกัน
- **`ENABLE_INSERT` และ `ENABLE_DELETE`** กำหนดว่าเอเจนต์เพิ่มหรือลบเอกสารได้หรือไม่
- ค่าตั้งอื่นทั้งหมดของ LightRAG ใส่ใน `.env` ได้ตาม [env.example ของ LightRAG v1.5.7](https://github.com/HKUDS/LightRAG/blob/v1.5.7/env.example)

## ความปลอดภัย

- **`LIGHTRAG_API_KEY` จำเป็นต้องกำหนด** ผู้ที่มี key นี้อ่าน เพิ่ม และลบเอกสารได้ทั้งหมด หน้าเว็บจะขอ key ก่อนใช้งานและเก็บไว้ในเบราว์เซอร์นั้น
- พอร์ต 9621 และ 8806 เปิดให้เครื่องอื่นในเครือข่ายเข้าถึงได้เป็นค่าเริ่มต้น (`WEBUI_PUBLISH_ADDR` และ `MCP_PUBLISH_ADDR` เป็น `0.0.0.0`) หากไม่จำเป็น ให้เปลี่ยนเป็น `127.0.0.1`
- MCP server ไม่ต้องใช้ key เป็นค่าเริ่มต้น ผู้ที่เข้าถึงพอร์ต 8806 ได้จะค้นและเพิ่มเอกสารได้ เมื่อเปิดให้เครื่องอื่นเข้าถึง ควรกำหนด `MCP_AUTH_TOKEN`
- เมื่อเปิดให้ใช้งานผ่านอินเทอร์เน็ต ควรวาง reverse proxy ที่ใช้ HTTPS ไว้ด้านหน้า เพื่อไม่ให้ key และเนื้อหาถูกส่งแบบไม่เข้ารหัส
- ค่าลับทั้งหมดอยู่ใน `.env` และเนื้อหาของคลังอยู่ใน `data/` ซึ่ง `.gitignore` กันไม่ให้ขึ้น git

## สำหรับนักพัฒนา

หน้าเว็บใน `webui/` คือไฟล์ที่ build แล้ว ซอร์สอยู่ในรูป patch ที่ใช้กับซอร์สของ LightRAG v1.5.7

| ไฟล์ | หน้าที่ |
|---|---|
| `webui-patch/lightrag-webui-v1.5.7.patch` | การแก้ไขทั้งหมดจาก `lightrag_webui/` ของ LightRAG v1.5.7 |
| `webui-patch/build.sh` | ดึงซอร์ส v1.5.7 ใส่ patch แล้ว build ใน Docker (`oven/bun`) และคัดลอกผลไปที่ `webui/` (เก็บ `kb-config.js` เดิมไว้) |
| `docker-compose.yml`, `.env.example` | ชุดติดตั้ง |

ส่วนที่แก้ใน patch:

- `src/features/kb/` (ใหม่): แถบบน (`TopBar`), ปุ่มภาษา (`LanguageSwitch`), แถบพับได้ (`SidePanel`), แถบเชื่อมต่อ (`ConnectPanel`) และแชตแถบขวา (`SideChat`) ซึ่งใช้ส่วนประกอบเดียวกับหน้าสืบค้นของ LightRAG
- `src/locales/th.json` (ใหม่) และคีย์ใหม่ใน `en.json` · เหลือเฉพาะภาษาไทยและอังกฤษ (`i18n.ts`, `browserLanguage.ts`)
- `App.tsx` (layout สามคอลัมน์), `SiteHeader.tsx` (เหลือแถวแท็บ ไม่มีโลโก้ ลิงก์ GitHub และปุ่มตั้งค่า), `LoginPage.tsx` (ไม่มีโลโก้)
- ธีมสว่างเสมอ (`ThemeProvider.tsx`), ฟอนต์ Sarabun (`index.html`, `index.css`), ไม่มีไอคอนของหน้า และชื่อแท็บ "คลังความรู้ (Knowledge Base)"
- สีหลัก #8B2332 (`--primary`, `--ring` และสีไอคอนใน `index.css`) และไม่แสดงป้าย "ไม่ต้องเข้าสู่ระบบ" (Guest Mode)

แก้หน้าเว็บ: clone LightRAG v1.5.7 ใส่ patch แก้ไขใน `lightrag_webui/` แล้วสร้าง patch ใหม่ด้วย `git add -A lightrag_webui && git diff --cached --binary -- lightrag_webui`
จากนั้นสั่ง `sh webui-patch/build.sh` และ `docker compose restart lightrag`

อัปเดต LightRAG: หน้าเว็บต้องตรงกับเวอร์ชันของเซิร์ฟเวอร์ ให้สร้าง patch สำหรับเวอร์ชันใหม่ (ใส่ patch เดิมแล้วแก้จุดที่ตรงกัน ตั้งชื่อ `lightrag-webui-<เวอร์ชัน>.patch`
แล้วสั่ง `LIGHTRAG_VERSION=<เวอร์ชัน> sh webui-patch/build.sh` และเปลี่ยน `LIGHTRAG_IMAGE` ให้ตรงกัน มุมขวาของแถวแท็บแสดงเวอร์ชันของเซิร์ฟเวอร์ หากมีเครื่องหมาย ⚠️ แปลว่าหน้าเว็บไม่ตรงกับเซิร์ฟเวอร์

## สัญญาอนุญาต

[MIT](LICENSE) © 2026 Chacharin Lertyosbordin
หน้าเว็บดัดแปลงจาก LightRAG WebUI ลิขสิทธิ์ของ LightRAG Team ภายใต้สัญญาอนุญาต MIT ([NOTICE.md](NOTICE.md))
