allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// সমস্ত সাব-মডিউলে kotlin-stdlib-এর ভার্সন 2.3.10 লক করা
subprojects {
    configurations.all {
        resolutionStrategy {
            eachDependency {
                if (requested.group == "org.jetbrains.kotlin") {
                    useVersion("2.3.10")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}