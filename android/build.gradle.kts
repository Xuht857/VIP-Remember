allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// 修复：部分第三方 Flutter 插件（如 app_settings 5.2.0）自带较低的 compileSdk（android-33），
// 但其依赖的新版 AndroidX（fragment 1.7.1 / window 1.2.0 / core-ktx 1.13.1 等）要求 compileSdk >= 34，
// 会导致 checkDebugAarMetadata 校验失败、APK 构建中断。
// 在此强制所有 Android 子工程（含插件模块）统一使用与 app 一致的 compileSdk = 35，确保 CI 可正常打包。
subprojects {
    afterEvaluate { subproject ->
        subproject.plugins.withId("com.android.library") {
            val android = subproject.extensions.getByType<com.android.build.api.dsl.LibraryExtension>()
            android.compileSdk = 35
        }
        subproject.plugins.withId("com.android.application") {
            val android = subproject.extensions.getByType<com.android.build.api.dsl.ApplicationExtension>()
            android.compileSdk = 35
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
