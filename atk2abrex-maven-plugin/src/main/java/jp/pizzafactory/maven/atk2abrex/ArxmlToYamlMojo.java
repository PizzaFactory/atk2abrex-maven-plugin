package jp.pizzafactory.maven.atk2abrex;

/*
 * Copyright 2016 PizzaFactory Project.
 *
 * Licensed under the EPL-1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.eclipse.org/legal/epl-v10.html
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import java.io.File;
import java.io.InputStream;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugins.annotations.LifecyclePhase;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;
import org.jruby.Ruby;
import org.jruby.embed.ScriptingContainer;

/**
 */
@Mojo(name = "arxml-to-yaml", defaultPhase = LifecyclePhase.PROCESS_SOURCES)
public class ArxmlToYamlMojo extends AbstractAtk2AbrexMojo {
    /**
     * Source files.
     */
    @Parameter(property = "file", required = true)
    protected File[] files;

    /**
     * Base location of param_info.yaml
     */
    @Parameter(defaultValue = "${project.build.directory}/atk2abrex")
    private File paramInfoDir;

    /**
     * True if overwriting param_info.yaml by the preset.
     */
    @Parameter(defaultValue = "true")
    private Boolean overwriteParamInfo;

    /**
     * Location of EcuExtractRef.
     */
    @Parameter(required = false)
    private File ecuExtractRef;

    @Override
    public void execute() throws MojoExecutionException {
        Ruby ruby = Ruby.newInstance();
        ScriptingContainer container = new ScriptingContainer();
        InputStream ist = YamlToArxmlMojo.class.getResourceAsStream("abrex.rb");
        container.runScriptlet(ist, "abrex.rb");

        final String sOutputDir = outputDirectory.getAbsolutePath();
        final List<Object> aExtraFile = Arrays.stream(files)
                .map(s -> s.getAbsolutePath()).collect(Collectors.toList());
        Object sFirstFile = aExtraFile.get(0);

        container.callMethod(ruby.getCurrentContext(), "XmlToYaml", sOutputDir,
                sFirstFile, aExtraFile);
    }

}
