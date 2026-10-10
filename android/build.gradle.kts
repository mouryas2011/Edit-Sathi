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

subprojects {
    val configureAndroid: (Project) -> Unit = { p ->
        val androidExt = p.extensions.findByName("android")
        if (androidExt != null) {
            val envSdkDir = System.getenv("ANDROID_HOME") ?: System.getenv("ANDROID_SDK_ROOT") ?: ""
            val ndkDir = file("$envSdkDir/ndk")
            val detectedNdk = if (ndkDir.exists()) {
                ndkDir.listFiles()
                    ?.filter { it.isDirectory && file("${it.absolutePath}/source.properties").exists() }
                    ?.map { it.name }
                    ?.sorted()
                    ?.lastOrNull()
            } else null

            if (detectedNdk != null) {
                try {
                    val method = androidExt.javaClass.getMethod("setNdkVersion", String::class.java)
                    method.invoke(androidExt, detectedNdk)
                } catch (_: Exception) {
                }
            }
        }
    }
    if (state.executed) {
        configureAndroid(this)
    } else {
        afterEvaluate { configureAndroid(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
