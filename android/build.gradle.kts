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

// 不再为第三方插件强制 compileSdk：已移除 app_settings 插件，
// 其 AndroidX 依赖曾要求 compileSdk>=34 导致 AAR metadata 校验失败；
// 同时避免自定义 subprojects/afterEvaluate 补丁与 Gradle 评估时序冲突。

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
