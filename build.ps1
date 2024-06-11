param(
    [string]$dartFilePath  # 从命令行接受一个完整的 Dart 文件路径
)

# 检查文件是否存在
if (Test-Path $dartFilePath) {
    # 获取文件的基本名字，无扩展名
    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($dartFilePath)

    # 定义输出的 EXE 文件路径
    $exeFilePath = "$fileNameWithoutExtension.exe"

    # 使用 Dart 编译器编译 Dart 文件到 EXE
    dart compile exe $dartFilePath -o $exeFilePath

    # 检查 EXE 文件是否成功创建
    if (Test-Path $exeFilePath) {
        # 获取 SCOOP shims 目录，使用字符串插值
        $scoopShimsPath = "${env:SCOOP}\shims"

        # 移动 EXE 文件到 SCOOP shims 目录
        Move-Item -Force -Path $exeFilePath -Destination $scoopShimsPath

        Write-Output "成功编译并移动 $exeFilePath 到 $scoopShimsPath"
    }
    else {
        Write-Output "编译失败，未能生成 EXE 文件"
    }
}
else {
    Write-Output "未找到文件 $dartFilePath"
}
