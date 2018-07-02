../usr/bin/julia -e "include(\"\$JULIA_HOME/../../analytics/collect_data.jl\"); set_logs_dir(\"\$JULIA_HOME/../../logs/\"); include(\"\$JULIA_HOME/../../analytics/generate_csv.jl\")"
