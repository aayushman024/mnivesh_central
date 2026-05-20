buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // required for google-services.json parsing
        classpath("com.google.gms:google-services:4.4.1")
        classpath("com.google.firebase:perf-plugin:1.4.2")
    }
}

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
    val configureAndroidProject = { proj: Project ->
        proj.extensions.findByName("android")?.let { androidExtension ->
            try {
                val compileOptions = androidExtension.javaClass.getMethod("getCompileOptions").invoke(androidExtension)
                val setSource = compileOptions.javaClass.methods.firstOrNull { it.name == "setSourceCompatibility" && it.parameterCount == 1 }
                val setTarget = compileOptions.javaClass.methods.firstOrNull { it.name == "setTargetCompatibility" && it.parameterCount == 1 }
                setSource?.invoke(compileOptions, JavaVersion.VERSION_17)
                setTarget?.invoke(compileOptions, JavaVersion.VERSION_17)
            } catch (e: Exception) {
                // Fail silently
            }
        }
    }
    if (project.state.executed) {
        configureAndroidProject(project)
    } else {
        project.afterEvaluate {
            configureAndroidProject(project)
        }
    }

    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }

    tasks.configureEach {
        if (this.javaClass.name.contains("KotlinCompile") || this.javaClass.name.contains("KotlinJvmCompile")) {
            try {
                val kotlinOptions = this.javaClass.getMethod("getKotlinOptions").invoke(this)
                kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java).invoke(kotlinOptions, "17")
            } catch (e: Exception) {
                try {
                    val compilerOptions = this.javaClass.getMethod("getCompilerOptions").invoke(this)
                    val jvmTarget = compilerOptions.javaClass.getMethod("getJvmTarget").invoke(compilerOptions)
                    try {
                        jvmTarget.javaClass.getMethod("set", String::class.java).invoke(jvmTarget, "17")
                    } catch (e2: Exception) {
                        jvmTarget.javaClass.getMethod("set", Object::class.java).invoke(
                            jvmTarget,
                            jvmTarget.javaClass.classLoader.loadClass("org.jetbrains.kotlin.gradle.dsl.JvmTarget")
                                .getField("JVM_17")
                                .get(null)
                        )
                    }
                } catch (ex: Exception) {
                    // Fail silently
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}