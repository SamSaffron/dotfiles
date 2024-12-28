return {
  { "tpope/vim-rails" },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "olimorris/neotest-rspec",
    },
    opts = function()
      -- Create the d-rspec script in /tmp
      local script = [=[
#!/bin/bash

args=()
for arg in "$@"; do
  if [[ "$arg" == ./* ]]; then
    args+=("$(realpath "$arg")")
  else
    args+=("$arg")
  fi
done

(
  cd /home/sam/Source/discourse || exit 1
  if [[ "${args[*]}" == *"plugins"* ]]; then
    export LOAD_PLUGINS=1
  fi
  ./bin/rspec "${args[@]}"

  # Find the output file from arguments
  output_file=""
  for ((i = 0; i < ${#args[@]}; i++)); do
    if [[ "${args[i]}" == "-o" ]]; then
      output_file="${args[i + 1]}"
      break
    fi
  done

  # If we found an output file, process it
  if [[ -n "$output_file" && -f "$output_file" ]]; then
    temp_file=$(mktemp)
    jq '(.examples[] | select(.id != null) | .id) |= sub("\\./plugins/[^/]+/"; "./")' "$output_file" >"$temp_file"
    mv "$temp_file" "$output_file"
  fi
)
]=]
      local script_path = "/tmp/d-rspec"
      local f = io.open(script_path, "w")
      if f then
        f:write(script)
        f:close()
        os.execute("chmod +x " .. script_path)
      end

      return {
        adapters = {
          ["neotest-rspec"] = {
            rspec_cmd = function()
              return {
                "/tmp/d-rspec",
              }
            end,
          },
        }
      }
    end,
  },
}
