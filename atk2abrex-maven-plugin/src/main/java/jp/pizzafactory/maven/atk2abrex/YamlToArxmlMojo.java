package jp.pizzafactory.maven.atk2abrex;

/*
 * Copyright 2001-2005 The Apache Software Foundation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import org.apache.commons.io.IOUtils;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugins.annotations.LifecyclePhase;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;
import org.jruby.Ruby;
import org.jruby.embed.ScriptingContainer;

/**
 */
@Mojo(name = "yaml-to-arxml", defaultPhase = LifecyclePhase.PROCESS_SOURCES)
public class YamlToArxmlMojo extends AbstractMojo {
    /**
     * Location of generated file.
     */
    @Parameter(defaultValue = "${project.build.directory}", property = "outputDir", required = true)
    private File outputDirectory;

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

    /**
     * Source YAML files.
     */
    @Parameter(property = "file", required = true)
    private File[] files;

    @Override
    public void execute() throws MojoExecutionException {
        Ruby ruby = Ruby.newInstance();
        ScriptingContainer container = new ScriptingContainer();
        InputStream ist = YamlToArxmlMojo.class.getResourceAsStream("abrex.rb");
        container.runScriptlet(ist, "abrex.rb");

        if (!paramInfoDir.exists()) {
            if (!paramInfoDir.mkdirs()) {
                throw new MojoExecutionException("Can't create paramInfoDir: "
                        + paramInfoDir.getAbsolutePath());
            }
        }
        container.put("TOOL_ROOT", paramInfoDir.getAbsolutePath());

        final File paramInfo = new File(paramInfoDir, "param_info.yaml");
        if (overwriteParamInfo) {
            try {
                FileOutputStream fos = new FileOutputStream(paramInfo);
                InputStream is = YamlToArxmlMojo.class
                        .getResourceAsStream("param_info.yaml");
                IOUtils.copy(is, fos);
            } catch (IOException e) {
                throw new MojoExecutionException(
                        "Error in writing param_info.yaml", e);
            }
        } else {
            if (!paramInfo.exists()) {
                throw new MojoExecutionException("Can't find "
                        + paramInfo.getAbsolutePath());
            }
        }

        final String sOutputDir = outputDirectory.getAbsolutePath();
        final List<Object> aArgData = Arrays.stream(files)
                .map(s -> s.getAbsolutePath()).collect(Collectors.toList());
        final String sEcuExtractRef;
        if (ecuExtractRef != null) {
            sEcuExtractRef = ecuExtractRef.getAbsolutePath();
        } else {
            sEcuExtractRef = null;
        }

        container.callMethod(ruby.getCurrentContext(), "YamlToXml", sOutputDir,
                aArgData, sEcuExtractRef);
    }
}
