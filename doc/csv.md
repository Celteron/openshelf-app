## CSV format

The first 19 columns are the Openreads columns, so the file can be read by Openreads-compatible tools. OpenShelf appends further columns (`isbn13`, `publisher`, `series`, `location`, `lending_status`, `quotes`, `id`, `slipcase_id`, …); the full list is `ExportService.csvColumns` in `lib/data/export/export_service.dart`.

Column | Values
--- | ---
title | Text
subtitle | Text
author | Text
description | Text
status | finished, in_progress, planned, abandoned, unknown
favourite | true, false
deleted | true, false
rating | 0.0 - 5.0, empty
pages | Number
publication_year | Number
isbn | Text (ISBN 10 or ISBN 13)
olid | Text (Open Library ID)
tags | Text (tags separated with \|\|\|\|\|)
my_review | Text
notes | Text
book_format | paperback, hardcover, ebook, audiobook
readings | List of readings separated by ";". Each reading is three values separated by "\|": start date (ISO 8601 String), finish date (ISO 8601 String), custom reading time (milliseconds Int)
date_added | ISO 8601 String
date_modified | ISO 8601 String
