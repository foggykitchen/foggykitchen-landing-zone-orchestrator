data "local_file" "fnjwtauth_dockerfile" {
  filename = "${local.functions_base_path}/fnjwtauth/Dockerfile"
}

data "local_file" "fnjwtauth_func_py" {
  filename = "${local.functions_base_path}/fnjwtauth/func.py"
}

data "local_file" "fnjwtauth_func_yaml" {
  filename = "${local.functions_base_path}/fnjwtauth/func.yaml"
}

data "local_file" "fnjwtauth_requirements_txt" {
  filename = "${local.functions_base_path}/fnjwtauth/requirements.txt"
}

data "local_file" "fnbackend_dockerfile" {
  filename = "${local.functions_base_path}/fnbackend/Dockerfile"
}

data "local_file" "fnbackend_func_py" {
  filename = "${local.functions_base_path}/fnbackend/func.py"
}

data "local_file" "fnbackend_func_yaml" {
  filename = "${local.functions_base_path}/fnbackend/func.yaml"
}

data "local_file" "fnbackend_requirements_txt" {
  filename = "${local.functions_base_path}/fnbackend/requirements.txt"
}
