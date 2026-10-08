import 'package:openreads/data/importers/book_importer.dart';
import 'package:openreads/data/importers/bookstats_csv_importer.dart';
import 'package:openreads/data/importers/bookstats_json_importer.dart';
import 'package:openreads/data/importers/bookwyrm_csv_importer.dart';
import 'package:openreads/data/importers/goodreads_csv_importer.dart';
import 'package:openreads/data/importers/json_backup_importer.dart';
import 'package:openreads/data/importers/legacy_backup_importer.dart';
import 'package:openreads/data/importers/openreads_csv_importer.dart';
import 'package:openreads/data/importers/openreads_json_importer.dart';
import 'package:openreads/data/importers/own_csv_importer.dart';
import 'package:openreads/data/importers/storygraph_csv_importer.dart';

/// Every supported import format, in detection order: the first importer that
/// recognises a file wins, so specific formats come before generic ones (an
/// OpenShelf backup also looks like `{"books": [...]}`, and Goodreads shares
/// `title`/`author` columns with Openreads).
List<BookImporter> defaultImporters() => <BookImporter>[
  JsonBackupImporter(),
  LegacyBackupImporter(),
  OpenreadsCsvImporter(),
  OpenreadsJsonImporter(),
  GoodreadsCsvImporter(),
  StoryGraphCsvImporter(),
  BookwyrmCsvImporter(),
  BookstatsCsvImporter(),
  BookstatsJsonImporter(),
  // Last: it accepts every CSV, so it only gets what nothing else recognised.
  OwnCsvImporter(),
];
