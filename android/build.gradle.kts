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

// Many third-party plugins (e.g. open_mail_launcher, package_info_plus) use a
// `kotlin { compilerOptions { ... } }` block in their build script but forget to apply the
// Kotlin Android plugin, which fails under newer Gradle/AGP that no longer apply it implicitly.
// Apply it for every Android subproject so their `kotlin {}` DSL resolves. Applying is idempotent,
// so plugins that already apply it themselves are unaffected.
subprojects {
    plugins.withId("com.android.library") {
        plugins.apply("org.jetbrains.kotlin.android")
    }
    plugins.withId("com.android.application") {
        plugins.apply("org.jetbrains.kotlin.android")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureNamespace = {
        val android = extensions.findByType<com.android.build.gradle.BaseExtension>()
        if (android != null && android.namespace == null) {
            android.namespace = project.group.toString()
        }
    }
    if (project.state.executed) {
        configureNamespace()
    } else {
        project.afterEvaluate {
            configureNamespace()
        }
    }
}
