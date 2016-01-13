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

import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugins.annotations.LifecyclePhase;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;
import org.jruby.Ruby;
import org.jruby.embed.ScriptingContainer;
import org.jruby.runtime.ThreadContext;

/**
 */
@Mojo(name = "make-paraminfo", defaultPhase = LifecyclePhase.PROCESS_SOURCES)
public class MakeParamInfoMojo extends AbstractAtk2AbrexMojo {

    /**
     * Location of the source ARXML
     */
    @Parameter(required = true)
    private File ecuConfigurationParameters;

    @Override
    public void execute() throws MojoExecutionException {
        Ruby ruby = Ruby.newInstance();
        ThreadContext context = ThreadContext.newContext(ruby);
        ScriptingContainer container = new ScriptingContainer();
        InputStream ist = YamlToArxmlMojo.class.getResourceAsStream("abrex.rb");
        container.runScriptlet(ist, "abrex.rb");

        final String sOutputDir = outputDirectory.getAbsolutePath();
        final String sFileName = ecuConfigurationParameters.getAbsolutePath();

        container.callMethod(context, "MakeParamInfo", sOutputDir, sFileName);
        container.terminate();
    }

}
