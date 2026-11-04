# WorkManager (pulled in by the Mobile Ads SDK) creates its Room database reflectively as
# <Name>_Impl. R8 full mode stripped that constructor, crashing release builds at launch with
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
