
"Parcel development server"

load("@build_bazel_rules_nodejs//internal/common:sources_aspect.bzl", "sources_aspect")
load(
    "@build_bazel_rules_nodejs//internal/js_library:js_library.bzl",
    "write_amd_names_shim",
)
load(
    "@build_bazel_rules_nodejs//internal/web_package:web_package.bzl",
    "additional_root_paths",
    "html_asset_inject",
)

# Avoid using non-normalized paths (workspace/../other_workspace/path)
def _to_manifest_path(ctx, file):
    if file.short_path.startswith("../"):
        return file.short_path[3:]
    else:
        return ctx.workspace_name + "/" + file.short_path

def _parcel_devserver(ctx):
    files = depset()
    dev_scripts = depset()
    for d in ctx.attr.deps:
        if hasattr(d, "node_sources"):
            files = depset(transitive = [files, d.node_sources])
        elif hasattr(d, "files"):
            files = depset(transitive = [files, d.files])
        if hasattr(d, "dev_scripts"):
            dev_scripts = depset(transitive = [dev_scripts, d.dev_scripts])

    if ctx.label.workspace_root:
        # We need the workspace_name for the target being visited.
        # Skylark doesn't have this - instead they have a workspace_root
        # which looks like "external/repo_name" - so grab the second path segment.
        # TODO(alexeagle): investigate a better way to get the workspace name
        workspace_name = ctx.label.workspace_root.split("/")[1]
    else:
        workspace_name = ctx.workspace_name

    # Create a manifest file with the sources in arbitrary order, and without
    # bazel-bin prefixes ("root-relative paths").
    # TODO(alexeagle): we should experiment with keeping the files toposorted, to
    # see if we can get performance gains out of the module loader.
    ctx.actions.write(ctx.outputs.manifest, "".join([
        workspace_name + "/" + f.short_path + "\n"
        for f in files.to_list()
    ]))

    amd_names_shim = ctx.actions.declare_file(
        "_%s.amd_names_shim.js" % ctx.label.name,
        sibling = ctx.outputs.script,
    )

    write_amd_names_shim(ctx.actions, amd_names_shim, ctx.attr.bootstrap)

    # Requirejs is always needed so its included as the first script
    # in script_files before any user specified scripts for the devserver
    # to concat in order.
    script_files = []
    script_files.extend(ctx.files.bootstrap)
    script_files.append(ctx.file._requirejs_script)
    script_files.append(amd_names_shim)
    script_files.extend(ctx.files.scripts)
    script_files.extend(dev_scripts.to_list())
    ctx.actions.write(ctx.outputs.scripts_manifest, "".join([
        workspace_name + "/" + f.short_path + "\n"
        for f in script_files
    ]))

    devserver_runfiles = [
        ctx.executable.parcel,
        ctx.outputs.manifest,
        ctx.outputs.scripts_manifest,
    ]
    devserver_runfiles += ctx.files.static_files
    devserver_runfiles += script_files
    devserver_runfiles += ctx.files._bash_runfile_helpers

    if ctx.file.index_html:
        injected_index = ctx.actions.declare_file("index.html")
        html_asset_inject(
            ctx.file.index_html,
            ctx.actions,
            ctx.executable._injector,
            additional_root_paths(ctx),
            [_to_manifest_path(ctx, f) for f in ctx.files.static_files],
            injected_index,
        )
        devserver_runfiles += [injected_index]


    packages = depset(["/".join([workspace_name, ctx.label.package])])

    ctx.actions.expand_template(
        template = ctx.file._launcher_template,
        output = ctx.outputs.script,
        substitutions = {
            "TEMPLATED_main": _to_manifest_path(ctx, ctx.executable.parcel),
            "TEMPLATED_index_html": _to_manifest_path(ctx, injected_index),
            "TEMPLATED_manifest": _to_manifest_path(ctx, ctx.outputs.manifest),
            "TEMPLATED_packages": ",".join(packages.to_list()),
            "TEMPLATED_port": str(ctx.attr.port),
            "TEMPLATED_scripts_manifest": _to_manifest_path(ctx, ctx.outputs.scripts_manifest),
            "TEMPLATED_workspace": workspace_name,
        },
        is_executable = True,
    )

    return [DefaultInfo(
        runfiles = ctx.runfiles(
            files = devserver_runfiles,
            # We don't expect executable targets to depend on the devserver, but if they do,
            # they can see the JavaScript code.
            transitive_files = depset(ctx.files.data, transitive = [files]),
            collect_data = True,
            collect_default = True,
        ),
    )]

parcel_devserver = rule(
    implementation = _parcel_devserver,
    attrs = {
        "data": attr.label_list(
            doc = "Dependencies that can be require'd while the server is running",
            allow_files = True,
        ),
        "additional_root_paths": attr.string_list(
            doc = """Additional root paths to serve `static_files` from.
            Paths should include the workspace name such as `["__main__/resources"]`
            """,
        ),
        "parcel": attr.label(
            doc = """Parcel Bundler.
            Defaults to parcel bundler in @npm//parcel-bundler npm package""",
            default = Label("@npm//parcel-bundler/bin:parcel"),
            executable = True,
            cfg = "host",
        ),
        "index_html": attr.label(
            allow_single_file = True,
            doc = """An index.html file, we'll inject the script tag for the bundle,
            as well as script tags for .js static_files and link tags for .css
            static_files""",
        ),
        "bootstrap": attr.label_list(
            doc = "Scripts to include in the JS bundle before the module loader (require.js)",
            allow_files = [".js"],
        ),
        "scripts": attr.label_list(
            doc = "User scripts to include in the JS bundle before the application sources",
            allow_files = [".js"],
        ),
        "port": attr.int(
            doc = """The port that the devserver will listen on.""",
            default = 5432,
        ),
        "static_files": attr.label_list(
            doc = """Arbitrary files which to be served, such as index.html.
            They are served relative to the package where this rule is declared.""",
            allow_files = True,
        ),
        "deps": attr.label_list(
            doc = "Targets that produce JavaScript, such as `ts_library`",
            allow_files = True,
            aspects = [sources_aspect],
        ),
        "_bash_runfile_helpers": attr.label(default = Label("@bazel_tools//tools/bash/runfiles")),
        "_injector": attr.label(
            default = "@build_bazel_rules_nodejs//internal/web_package:injector",
            executable = True,
            cfg = "host",
        ),
        "_launcher_template": attr.label(allow_single_file = True, default = Label("//builddefs/internal:launcher_template.sh")),
        "_requirejs_script": attr.label(allow_single_file = True, default = Label("//builddefs/internal:require.js")),
    },
    outputs = {
        "manifest": "%{name}.MF",
        "script": "%{name}.sh",
        "scripts_manifest": "scripts_%{name}.MF",
    },
    doc = """parcel_devserver is a simple development server intended for a quick "getting started" experience.
Additional documentation at https://github.com/alexeagle/angular-bazel-example/wiki/Running-a-devserver-under-Bazel
""",
)

def parcel_devserver_macro(name, data = [], args = [], visibility = None, tags = [], testonly = 0, **kwargs):
    """Macro for creating a `parcel_devserver`
    This macro re-exposes a `sh_binary` and `parcel_devserver` target that can run the
    actual devserver implementation.
    The `parcel_devserver` rule is just responsible for generating a launcher script
    that runs the parcel dev server. The `sh_binary` is the primary
    target that matches the specified "name" and executes the generated bash
    launcher script.
    This is re-exported in `//buildefs:index.bzl` as `parcel_devserver` so if you load the rule
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
    parcel_devserver(
        name = "%s_launcher" % name,
        data = data + [
            "@bazel_tools//tools/bash/runfiles",
            "@nodejs//:bin/node_repo_args.sh",
            "@npm//parcel-bundler",
            "@nodejs//:node_bin",
            "@npm//parcel-bundler/bin:parcel",
            "@npm//parcel-bundler:parcel-bundler__files",
            "//builddefs/internal:require.js",
        ],
        testonly = testonly,
        visibility = ["//visibility:private"],
        tags = tags,
        **kwargs
    )

    # Expose the manifest file label
    native.alias(
        name = "%s.MF" % name,
        actual = "%s_launcher.MF" % name,
        visibility = visibility,
    )

    native.sh_binary(
        name = name,
        args = args,
        # Users don't need to know that these tags are required to run under ibazel
        tags = tags + [
            # Tell ibazel not to restart the devserver when its deps change.
            "ibazel_notify_changes",
            # Tell ibazel to serve the live reload script, since we expect a browser will connect to
            # this program.
            "ibazel_live_reload",
        ],
        srcs = ["%s_launcher.sh" % name],
        data = [":%s_launcher" % name],
        testonly = testonly,
        visibility = visibility,
    )