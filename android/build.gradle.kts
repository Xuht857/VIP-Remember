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
// 在根工程统一强制所有含 android 扩展的子工程使用 compileSdk = 35（与 app 一致）。
// 用反射设置，以规避根脚本 classpath 中缺少 AGP DSL 类型（LibraryExtension 等）导致脚本无法编译的问题。
subprojects {
    afterEvaluate {
        val ext = extensions.findByName("android")
        if (ext != null) {
            // compileSdk 在 AGP 中声明为可空 Int?，JVM 方法参数实际为 Integer；
            // 这里按方法名+单参数查找（不限定 int/Integer），再用 invoke(ext, 35)
            // 让 Kotlin 的 35 自动装箱，两种签名都能命中。
            val setter = ext.javaClass.methods.firstOrNull { m ->
                (m.name == "setCompileSdk" || m.name == "setCompileSdkVersion") && m.parameterCount == 1
            }
            setter?.invoke(ext, 35)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
