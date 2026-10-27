package org.sequeless.template;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/**
 * Mechanically enforced hexagonal boundaries for this module. Four rules, copied from
 * ontology's facet-core (spec 2, §5). When a repo adds a Sequeless dependency, widen the fourth
 * rule to that dependency's package. An adapter module drops that rule and relies on Maven
 * dependency declarations instead.
 */
@AnalyzeClasses(
        packages = "org.sequeless.template",
        importOptions = {ImportOption.DoNotIncludeTests.class})
class BoundaryRulesTest {

    @ArchTest
    static final ArchRule module_is_free_of_spring = noClasses()
            .should()
            .dependOnClassesThat()
            .resideInAnyPackage("org.springframework..")
            .as("this module must stay transport-agnostic: no Spring dependency");

    // TODO: drop allowEmptyShould once real types land in api/spi. There are none yet.
    @ArchTest
    static final ArchRule api_and_spi_types_are_public = classes()
            .that()
            .resideInAnyPackage("org.sequeless.template.api..", "org.sequeless.template.spi..")
            .and()
            .areTopLevelClasses()
            .and()
            .haveSimpleNameNotEndingWith("package-info")
            .should()
            .bePublic()
            .as("the published contract (api + spi) must be exported as public types")
            .allowEmptyShould(true);

    @ArchTest
    static final ArchRule api_and_spi_never_depend_on_internal = noClasses()
            .that()
            .resideInAnyPackage("org.sequeless.template.api..", "org.sequeless.template.spi..")
            .should()
            .dependOnClassesThat()
            .resideInAnyPackage("org.sequeless.template.internal..")
            .as("api and spi must not depend on internal, which is implementation detail");

    @ArchTest
    static final ArchRule module_depends_only_on_java_and_itself = noClasses()
            .should()
            .dependOnClassesThat()
            .resideOutsideOfPackages("java..", "org.sequeless.template..")
            .as("this module depends on the JDK and itself only; widen per declared dependency");
}
