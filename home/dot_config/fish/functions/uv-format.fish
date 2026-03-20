function uv-format --description "ruff でフォーマットとリントを実行"
    uvx ruff format
    uvx ruff check --fix --extend-select I
end
