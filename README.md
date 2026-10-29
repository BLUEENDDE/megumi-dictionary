# 印尼语易混词

一个本地优先的 Android 背词 App：不做词表堆砌，而是把两个容易混的词放在一起，**按差异板块逐条对比**，再用二选一填空复习。

Flutter 写的，数据全在手机上，不需要服务器。

## 现在能做什么

- **词对列表**：两个词对撞 + 一句话差异 + 标签，支持搜索过滤
- **对比详情**：按「差异轴」逐条摊开（适用对象 / 常见搭配 / 语域…），配一对最小对比句
- **词族关系网**：每个词右边一个按钮，点开是它的词根派生的整族词（meN- / di- / peN-… 按词缀着色），看得到"一个词根怎么长出十几种用法"
- **二选一复习**：选词填空，答对绿框+勾，答错红框+抖动并给出正确项和差异说明
- **记忆调度（SRS）**：每个词对有自己的盒子等级（0–6），答对推进、答错打回 0；间隔 1/2/4/7/15/30 天，到期优先复习
- **自建词对**：完整表单录入（两词、释义、差异、多条轴、例句），本地保存，长按删除，可编辑
- **进度持久化**：练过多少次、正确率、今日题数，关掉 App 不丢
- **导出 / 导入备份**：一份 JSON 文本，复制粘贴即可迁移或留底
- **深色模式**：跟随系统 / 浅色 / 深色，选择会记住

## 目录

```
lib/
  main.dart                 入口，主题装配
  models/word_pair.dart     数据结构 + JSON 序列化
  data/sample_data.dart     内置示例词库（6 组）
  data/word_families.dart   词根词族（21 族）
  services/
    progress_store.dart     SRS 状态 + 练习记录
    user_pairs_store.dart   自建词对存取
    settings_store.dart     主题模式
    backup_service.dart     备份编解码
  screens/                  首页 / 详情 / 复习 / 添加编辑 / 设置
  theme/palette.dart        浅色与暗色调色板
  widgets/ui_kit.dart       转场、例句高亮
  preview_main.dart         仅用于截图预览，不参与打包
```

## 开发

```bash
flutter run                       # 连手机调试，r 热重载
flutter test                      # 单元 + widget 测试
flutter build apk --release       # 出安装包
```

产物：`build/app/outputs/flutter-apk/app-release.apk`

## 说明

- 内置的 6 组词对是示例，真正的价值在你往里加自己的易混词
- 打包用的是 Flutter 默认调试签名，自己装没问题，不能上架商店
- 词条例句必须包含目标词，否则那道填空题会被自动跳过
