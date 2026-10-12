using NetArchTest.Rules;

namespace Workshop.Architecture.Tests;

/// <summary>
/// 架構相依規則（ARCH-01、02、03、05、06）。測試失敗訊息列出違規型別；
/// 不得刪除、略過或放寬這些測試來消除失敗（TEST-07）。
/// </summary>
public class LayerDependencyTests
{
    [Fact]
    public void Domain_DoesNotDependOnOtherLayersOrInfrastructureFrameworks() =>
        AssertRule(ArchitectureRules.DomainHasNoOuterDependency(), "ARCH-01／ARCH-02");

    [Fact]
    public void Application_DoesNotDependOnInfrastructureWebOrDataAccess() =>
        AssertRule(ArchitectureRules.ApplicationHasNoOuterDependency(), "ARCH-01／ARCH-03");

    [Fact]
    public void Infrastructure_DoesNotDependOnWeb() =>
        AssertRule(ArchitectureRules.InfrastructureHasNoWebDependency(), "ARCH-01");

    [Fact]
    public void Web_UsesInfrastructureOnlyInCompositionRoot() =>
        AssertRule(ArchitectureRules.WebUsesInfrastructureOnlyInCompositionRoot(), "ARCH-05／ARCH-06");

    private static void AssertRule(TestResult result, string ruleIds) =>
        Assert.True(
            result.IsSuccessful,
            $"{ruleIds} 違規型別：{Environment.NewLine}{ArchitectureRules.DescribeFailures(result)}");
}
