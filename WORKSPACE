# https://github.com/bazelbuild/rules_typescript/blob/master/README.md
workspace(
    name = "bazel_parcel",
    managed_directories = {"@npm": ["node_modules"]},
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

http_archive(
    name = "build_bazel_rules_typescript",
    url = "https://github.com/bazelbuild/rules_typescript/archive/0.21.0.zip",
    strip_prefix = "rules_typescript-0.21.0",
    sha256 = "e4f51c408ed3278a3a1dd227564a69f293ae2ac4ae1564b3a6d2637ae9447b47",
)
http_archive(
    name = "build_bazel_rules_nodejs",
    urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/0.37.1/rules_nodejs-0.37.1.tar.gz"],
    sha256 = "da217044d24abd16667324626a33581f3eaccabf80985b2688d6a08ed2f864be"
)

# bazel-skylb 0.8.0 released 2019.03.20 (https://github.com/bazelbuild/bazel-skylib/releases/tag/0.8.0)
skylib_version = "0.8.0"
http_archive(
    name = "bazel_skylib",
    type = "tar.gz",
    url = "https://github.com/bazelbuild/bazel-skylib/releases/download/{}/bazel-skylib.{}.tar.gz".format (skylib_version, skylib_version),
    sha256 = "2ef429f5d7ce7111263289644d233707dba35e39696377ebab8b0bc701f7818e",
)

# proto_library rules implicitly depend on @com_google_protobuf//:protoc,
# which is the proto-compiler.
# This statement defines the @com_google_protobuf repo.
http_archive(
    name = "com_google_protobuf",
    strip_prefix = "protobuf-3.9.1",
    sha256 = "98e615d592d237f94db8bf033fba78cd404d979b0b70351a9e5aaff725398357",
    urls = ["https://github.com/google/protobuf/archive/v3.9.1.tar.gz"],
)

http_archive(
    name = "rules_proto",
    sha256 = "602e7161d9195e50246177e7c55b2f39950a9cf7366f74ed5f22fd45750cd208",
    strip_prefix = "rules_proto-97d8af4dc474595af3900dd85cb3a29ad28cc313",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_proto/archive/97d8af4dc474595af3900dd85cb3a29ad28cc313.tar.gz",
        "https://github.com/bazelbuild/rules_proto/archive/97d8af4dc474595af3900dd85cb3a29ad28cc313.tar.gz",
    ],
)

load("@rules_proto//proto:repositories.bzl", "rules_proto_dependencies", "rules_proto_toolchains")
rules_proto_dependencies()
rules_proto_toolchains()

# Setup the NodeJS toolchain
load("@build_bazel_rules_nodejs//:defs.bzl", "node_repositories", "yarn_install")

# Setup Bazel managed npm dependencies with the `yarn_install` rule.
# The name of this rule should be set to `npm` so that `ts_library` and `ts_web_test_suite`
# can find your npm dependencies by default in the `@npm` workspace. You may
# also use the `npm_install` rule with a `package-lock.json` file if you prefer.
# See https://github.com/bazelbuild/rules_nodejs#dependencies for more info.
yarn_install(
  name = "npm",
  package_json = "//:package.json",
  yarn_lock = "//:yarn.lock",
)

node_repositories(
    package_json = ["//:package.json"]
)

# Install bazel dependencies comming from npm packages (i.e. packages starting with @bazel/)
load("@npm//:install_bazel_dependencies.bzl", "install_bazel_dependencies")
install_bazel_dependencies()

# Setup the rules_typescript tooolchain
load("@npm_bazel_typescript//:defs.bzl", "ts_setup_workspace")
ts_setup_workspace()