{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.custom.cli.neovim;
  system = pkgs.stdenv.hostPlatform.system;
  hasLlmAgents = inputs.llm-agents.packages ? ${system};

  # Bundle local ./lua and ./after/ftplugin directories as a Neovim plugin
  # so they live in /nix/store on Neovim's runtimepath.
  icdts-nvim-config = pkgs.vimUtils.buildVimPlugin {
    pname = "icdts-nvim-config";
    version = "0.1.0";
    doCheck = false;
    src = pkgs.lib.fileset.toSource {
      root = ./.;
      fileset = pkgs.lib.fileset.unions [
        ./lua
        ./after
      ];
    };
  };

  agentDefs = [
    {
      enabled = cfg.agents.antigravity;
      bin = "agy";
      pkg = inputs.llm-agents.packages.${system}.antigravity-cli;
    }
    {
      enabled = cfg.agents.copilot;
      bin = "copilot";
      pkg = inputs.llm-agents.packages.${system}.copilot-cli;
    }
  ];

  enabledAgents = optionals (hasLlmAgents && cfg.agents.enable) (
    filter (a: a.enabled) agentDefs
  );

  extraPackages =
    with pkgs;
    [
      # Search & utility tools
      curl
      ripgrep

      # LSP servers & formatters
      ccls
      ruby-lsp
      gopls
      lua-language-server
      nixd
      nixfmt
    ]
    ++ map (a: a.pkg) enabledAgents;

  expectedAiBins = map (a: a.bin) enabledAgents;

  plugins = with pkgs.vimPlugins; [
    icdts-nvim-config

    catppuccin-nvim # coloring
    nvim-treesitter.withAllGrammars # syntax highlighting
    plenary-nvim
    which-key-nvim # popup showing what key presses do what
    indent-blankline-nvim # highlighting indent
    nvim-lspconfig # lsp integration
    lualine-nvim # status line
    telescope-nvim # file nav
    telescope-fzf-native-nvim # use fzf integration

    nvim-cmp # completion engine
    cmp-buffer # completion sourced from buffer
    cmp-path # completion of filesystem paths
    cmp-cmdline # vim's command line completion
    cmp-nvim-lsp # completion sourced from lsp
  ];

  neovimPkg =
    (pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
      viAlias = true;
      vimAlias = true;
      withRuby = false;
      withPython3 = false;
      luaRcContent = builtins.readFile ./init.lua;
      inherit plugins;
      wrapperArgs = [
        "--suffix"
        "PATH"
        ":"
        (pkgs.lib.makeBinPath extraPackages)
        "--set"
        "NVIM_AI_AGENTS"
        (concatStringsSep "," expectedAiBins)
      ];
    }).overrideAttrs
      (old: {
        doCheck = true;
        checkPhase = ''
          runHook preCheck
          export HOME="$TMPDIR"
          $out/bin/nvim --headless -i NONE -c "luafile ${./tests/smoke.lua}"
          runHook postCheck
        '';
      });
in
{
  options.custom.cli.neovim = {
    enable = mkEnableOption "neovim";
    agents = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Master toggle for all AI CLI agents and Neovim AI sidebar integration.";
      };
      antigravity = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to bundle Antigravity CLI (agy) into Neovim's PATH.";
      };
      copilot = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to bundle GitHub Copilot CLI into Neovim's PATH.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ neovimPkg ];
    home.sessionVariables.EDITOR = "nvim";
  };
}
