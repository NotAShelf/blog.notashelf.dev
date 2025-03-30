---
title: What is nixConfig, Should You Trust It?
date: 2025-02-28
description: A quick look into Nix's controversial nixConfig settings
wordcount: process-anyway
---

# What is nixConfig, and Should You Trust It?

[article on flakes]: https://wiki.nixos.org/wiki/Flakes#Flake_schema

Those of you who have been a part of the Nix ecosystem, more specifically a part
of the community that often deals with flakes, [^1] has no doubt noticed or
perhaps actively uses the `nixConfig` attribute in a `flake.nix`. For those
unfamiliar, The NixOS wiki in the [article on flakes] defines it as follows:

> `nixConfig` is an attribute set of values which reflect the values given to
> nix.conf. This can extend the normal behavior of a user's nix experience by
> adding flake-specific configuration, such as a binary cache.

Sounds good right? Wrong. It is a ticking time bomb waiting to explode. Being
able to modify your `nix.conf` on your system is equivalent of having full
control of the Nix daemon on your system. When you check out to a repository
that uses flakes and run, say, `nix run` on a package you will get a prompt
asking you whether you trust the configuration settings set in the flake.

```nix
$ nix run .#foobar
do you want to allow configuration setting 'extra-substituters' to be set to 'https://nix-community.cachix.org' (y/N)? y
do you want to permanently mark this value as trusted (y/N)? y
```

Accept it, and the door is wide open. More technical users may be inclined to
object, saying they will know the changes that will be made to the system. They
are not wrong, but if that is their argument then they are incredibly dense.

## Security Implications

You should be fully ware that changes made through `nixConfig` will affect all
Nix operations within the flake, possibly increasing the attack surface through
the introduction of unsafe, unsigned and malicious binary caches to the
configuration to pull unsafe binaries. It can also introduce `allowUnfree`,
which might cause ideological or legal (_see: licensing_) issues depending on
the context. `nixConfig` is a powerful option that can set options that you do
not want changed haphazardly. From package sources to substitution and to
trusted keys your build process will use. Often times, this option is more of a
hassle than it is convenient. Although, some might also find it incredibly
useful.

There exists a `accept-flake-config` option that you can set as
`nix.settings.accept-flake-config`. Please make sure to keep this set to _false_
as accepting those options automatically, and without the prompt above, is more
insecure than you think. There are _many_ vulnerabilities that can come from
blindly trusting a flake's `nixConfig`.

If you want to go a step further, I have been running the following patch by the
awesome [@eclairevoyant](https://github.com/eclairevoyant) to add a
_reject-flake-config_ option to [Lix, the Nix fork](https://lix.systems) to
automatically reject flakes' `nixConfig`.

```diff
From 25f1b8e714b13d2aa6fcdc67bedf1544bd17e45a Mon Sep 17 00:00:00 2001
From: =?UTF-8?q?=C3=A9clairevoyant?=
 <848000+eclairevoyant@users.noreply.github.com>
Date: Fri, 19 Jul 2024 09:23:27 -0400
Subject: [PATCH 3/4] feat: option reject-flake-config

---
 src/libexpr/flake/config.cc       | 5 +++++
 src/libfetchers/fetch-settings.hh | 4 ++++
 2 files changed, 9 insertions(+)

diff --git a/src/libexpr/flake/config.cc b/src/libexpr/flake/config.cc
index 558b3e9b9..bf558e5e2 100644
--- a/src/libexpr/flake/config.cc
+++ b/src/libexpr/flake/config.cc
@@ -51,6 +51,11 @@ void ConfigFile::apply()
         else
             assert(false);

+        if (nix::fetchSettings.rejectFlakeConfig) {
+            warn("ignoring untrusted flake configuration setting '%s' due to the '%s' setting.", name, "reject-flake-config");
+            continue;
+        }
+
         bool trusted = whitelist.count(baseName);
         if (!trusted) {
             switch (nix::fetchSettings.acceptFlakeConfig.get()) {
diff --git a/src/libfetchers/fetch-settings.hh b/src/libfetchers/fetch-settings.hh
index 93123463c..67f2e4d14 100644
--- a/src/libfetchers/fetch-settings.hh
+++ b/src/libfetchers/fetch-settings.hh
@@ -108,6 +108,10 @@ struct FetchSettings : public Config
         )",
         {}, true, Xp::Flakes};

+    Setting<bool> rejectFlakeConfig{this, false, "reject-flake-config",
+        "Whether to reject nix configuration (including whitelisted settings) from a flake without prompting.",
+        {}, true, Xp::Flakes};
+
     Setting<std::string> commitLockFileSummary{
         this, "", "commit-lockfile-summary",
         R"(
--
```

Give it a try if you are running Lix and don't mind the rebuilds. This will
reject the flake config, skipping the prompt to accept the values set in
`nixConfig`.

## Looking into nixConfig

Now that the ultimatum is out of the way, let's take a look at what `nixConfig`
is and what it really does. As mentioned above, it is _an attribute set of
values which reflect the values given to nix.conf._ That in itself is a vague
explanation, but it gets the point across: it is an attribute set that takes the
same values you would pass to `nix.settings`, which is used to construct the
`nix.conf` in a typical NixOS configuration. Or, if you are using Nix
standalone, it is an attribute set of values that would be converted to their
`nix.conf` equivalents.

It is defined and used in
[libflake/flake/config.cc](https://github.com/NixOS/nix/blob/92c4789ec72a5bf485679f9a5e5a244e553fb03d/src/libflake/flake/config.cc).
According to the `getDataDir()` function, this will get the full path of Nix's
data directory (One of `NIX_DATA_DIRECTORY`, `XDG_DATA_HOME` or
`$HOME/.local/share/nix/` in that order) and create `trusted-settings.json`.
Nice, now we know where to look if we _accidentally_ accept the prompt, or ever
want to retract our blind trust into a flake's author.

Other than this path, there is not much to `nixConfig`. Your system does not
interact with it until you enter the directory of a flake and run a command that
triggers evaluation, in which case
[`ConfigFile::apply`](https://github.com/NixOS/nix/blob/92c4789ec72a5bf485679f9a5e5a244e553fb03d/src/libflake/flake/config.cc#L32C1-L79C2)
is invoked.

## Conclusion

In short, `nixConfig` is a powerful attribute that _may or may not come in
handy_ at the cost of exposing a very large attack vector. Even a lazy attacker
can exploit it, and the user is not properly warned about the consequences of
accepting the prompt (which defaults to true for some reason.)

This has been your ever-so-informative technical rant on Nix and it's
undocumented mess. Hope you learned something today, cheers.

[^1]: If you don't use Nix flakes, or have no idea what they are then this post
    does not apply to you. In fact, I'm glad you're saving yourself the
    headache!
