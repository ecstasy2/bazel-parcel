
""

load("@npm_bazel_typescript//:index.bzl", "ts_library")

load(":js_library.bzl", "js_library")


JsPackageSources = provider("transitive_sources_deps")


def _js_package_sources_impl(ctx):
    transitive_sources_deps = depset(ctx.files.srcs)

    for dep in ctx.attr.deps:
        if JsPackageSources in dep:
            transitive_sources_deps = depset(transitive = [
                transitive_sources_deps,
                dep[JsPackageSources].transitive_sources_deps
            ])
    
    print("{}".format(transitive_sources_deps))
    return [
        JsPackageSources(transitive_sources_deps = transitive_sources_deps),
        DefaultInfo(data_runfiles = ctx.runfiles(files = transitive_sources_deps.to_list())),
    ]


_js_package_sources = rule(
    implementation = _js_package_sources_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".js", ".jsx", ".ts", ".tsx", ".json", ".css"]),
        "deps": attr.label_list(),
    }
)

def rasta_js_package(
    exclude_srcs = [],
    deps_package = [],
    data = [], 
    args = [], 
    visibility = None, 
    tags = [], 
    testonly = 0, 
    deps = [], 
    **kwargs):

    """Macro that manages 
    This is re-exported in `//buildefs:index.bzl` as `rasta_js_package` so if you load the rule
    from there, you actually get this macro.
    Args:
      name: Name of the devserver target
      data: Runtime dependencies for the devserver
      args: Command line arguments that will be passed to parcel
      visibility: Visibility of the devserver targets
      tags: Standard Bazel tags, this macro adds a couple for ibazel
      testonly: Whether the devserver should only run in `bazel test`
      **kwargs: passed through to `parcel_devserver`
    """

    pkg_name = native.package_name().split("/")[-1]
    js_target_name = "js_lib"
    ts_target_name = "ts_lib"

    js_srcs = native.glob(
        ["*.js", "*.jsx"],
        exclude = exclude_srcs + ["*.test.js", "*.test.jsx"],
    )

    ts_srcs = native.glob(
        ["*.ts", "*.tsx"],
        exclude = exclude_srcs + ["*.test.ts", "*.test.tsx"],
    )

    test_srcs = native.glob([
        "*.spec.js",
        "*.spec.jsx",
        "*.spec.ts",
        "*.spec.tsx",
    ])

    js_library(
        name = js_target_name,
        srcs = js_srcs,
        testonly = testonly,
        tags = tags,
        visibility = ["//visibility:public"],
    )

    # test_deps = test_deps + [":" + pkg_name] + deps

    ts_library(
        name = ts_target_name,
        data = data,
        testonly = testonly,
        deps = deps + [":" + js_target_name],
        visibility = ["//visibility:public"],
        tags = tags,
        srcs = ts_srcs
    )

    package_deps = [package_label + ":all_sources" for package_label in deps_package]

    _js_package_sources(
        name = "all_sources",
        srcs = js_srcs + ts_srcs + native.glob(["*.css", "*.json"]),
        deps = deps + package_deps ,
        visibility = ["//visibility:public"],
        tags = tags + ["rasta_sources"]
    )

    # native.filegroup(
    #     name = "sources",
    #     srcs = js_srcs + ts_srcs,
    #     visibility = ["//visibility:public"],
    #     tags = tags + ["rasta_sources"]
    # )
