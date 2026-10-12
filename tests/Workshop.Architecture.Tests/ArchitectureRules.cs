using System.Reflection;
using NetArchTest.Rules;

namespace Workshop.Architecture.Tests;

/// <summary>
/// docs/team-rules/architecture.md 的相依規則，以編譯後組件檢查 ARCH-01、02、03、05、06。
/// 依組件名稱載入；組件內尚無型別時規則視為通過。
/// 層級或組裝入口名稱變更時，同步更新 docs/project-context.md 與此檔。
/// </summary>
internal static class ArchitectureRules
{
    internal const string DomainNamespace = "Workshop.Domain";
    internal const string ApplicationNamespace = "Workshop.Application";
    internal const string InfrastructureNamespace = "Workshop.Infrastructure";
    internal const string WebNamespace = "Workshop.Web";

    /// <summary>組裝入口（ARCH-06）：只有這些型別可以引用 Infrastructure。</summary>
    internal static readonly string[] CompositionRootTypeNames = ["Program"];

    private static readonly string[] DataAccessNamespaces = ["Microsoft.EntityFrameworkCore", "System.Data"];
    private const string AspNetCoreNamespace = "Microsoft.AspNetCore";

    /// <summary>ARCH-01、ARCH-02：Domain 不依賴其他產品層、MVC／HTTP、ORM、資料庫連線與 HttpClient。</summary>
    internal static TestResult DomainHasNoOuterDependency() =>
        Types.InAssembly(Load(DomainNamespace))
            .ShouldNot()
            .HaveDependencyOnAny(
            [
                ApplicationNamespace, InfrastructureNamespace, WebNamespace,
                AspNetCoreNamespace, "System.Net.Http", .. DataAccessNamespaces,
            ])
            .GetResult();

    /// <summary>ARCH-01、ARCH-03：Application 不依賴 Infrastructure、Web、ASP.NET Core 型別與資料存取實作。</summary>
    internal static TestResult ApplicationHasNoOuterDependency() =>
        Types.InAssembly(Load(ApplicationNamespace))
            .ShouldNot()
            .HaveDependencyOnAny([InfrastructureNamespace, WebNamespace, AspNetCoreNamespace, .. DataAccessNamespaces])
            .GetResult();

    /// <summary>ARCH-01：Infrastructure 不依賴 Web 與 MVC。</summary>
    internal static TestResult InfrastructureHasNoWebDependency() =>
        Types.InAssembly(Load(InfrastructureNamespace))
            .ShouldNot()
            .HaveDependencyOnAny([WebNamespace, "Microsoft.AspNetCore.Mvc"])
            .GetResult();

    /// <summary>ARCH-05、ARCH-06：Web 除組裝入口外，不直接使用 Infrastructure 或資料存取實作（含 Controller、lambda 與 Razor View）。</summary>
    internal static TestResult WebUsesInfrastructureOnlyInCompositionRoot() =>
        Types.InAssembly(Load(WebNamespace))
            .That()
            .DoNotHaveName(CompositionRootTypeNames)
            .ShouldNot()
            .HaveDependencyOnAny([InfrastructureNamespace, .. DataAccessNamespaces])
            .GetResult();

    internal static string DescribeFailures(TestResult result) =>
        string.Join(Environment.NewLine, (result.FailingTypes ?? []).Select(t => "  " + t.FullName));

    private static Assembly Load(string assemblyName) => Assembly.Load(new AssemblyName(assemblyName));
}
