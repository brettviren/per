#!/usr/bin/env python
'''
A simple uv based package manager.

Basically a loop over a package list calling uv tool.
'''


import os
import sh
from io import StringIO
import click
from pathlib import Path
from tomllib import loads as toml_loads, TOMLDecodeError

def config_home():
    '''
    Return the default configuration home
    '''
    try:
        return Path(os.environ['XDG_CONFIG_HOME'])
    except KeyError:
        return Path.home() / ".config"

default_config_filename = config_home() / "per" / "config.toml"

@click.group()
@click.option("-c","--config",
              default=default_config_filename,
              help="Configuration file in TOML syntax")
@click.pass_context
def cli(ctx, config):
    '''
    A simple personal package manager based on uv.
    '''
    try:
        ctx.obj = {
            "config": toml_loads(open(config).read()),
            "config_filename": config
        }
    except TOMLDecodeError as e:
        click.echo(f"Error parsing TOML configuration: {e}", err=True)
    except Exception as err:
        click.echo(f'Failed to parse {config}: {err}')
        click.echo(f'Using empty config')
        ctx.obj = dict()


@cli.command("list")
@click.pass_context
def cmd_list(ctx):
    '''
    List configured packages"
    '''

    cfg = ctx.obj["config"]
    for pname, pdata in cfg.get("package").items():
        print (pname, pdata.get("source"))


@cli.command("install")
@click.argument("packages", nargs=-1)
@click.pass_context
def cmd_install(ctx, packages):
    '''
    Install packages.  If no packages, apply to all
    '''

    pcfg = ctx.obj["config"].get("package")

    if not packages:
        packages = list(pcfg.keys())

    args = ["tool", "install"]

    uti = sh.uv.bake(args)

    for pname in packages:
        pdata = pcfg[pname]
        withs = ['--with='+w for w in pdata.get("with", [])]
        source = pdata["source"]
        out = StringIO()
        err = StringIO()
        cmd = uti.bake(withs + [source])
        print(cmd)
        cmd(_out=out, _err=err)
        if (out):
            click.echo(out.getvalue())
        if (err):
            click.echo(err.getvalue())



@cli.command("upgrade")
@click.argument("packages", nargs=-1)
@click.pass_context
def cmd_upgrade(ctx, packages):
    '''
    Install packages.  If no packages, apply to all
    '''

    pcfg = ctx.obj["config"].get("package")

    if not packages:
        packages = list(pcfg.keys())

    args = ["tool", "upgrade"]

    uti = sh.uv.bake(args)

    for pname in packages:
        pdata = pcfg[pname]
        out = StringIO()
        err = StringIO()
        cmd = uti.bake([pname])
        print(cmd)
        cmd(_out=out, _err=err)
        if (out):
            click.echo(out.getvalue())
        if (err):
            click.echo(err.getvalue())



# todo:
# - [ ] download dev package
# - [ ] check what packages have pending commits/pushes/pulls
# - [ ] install from dev package.
